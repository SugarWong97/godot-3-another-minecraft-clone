extends Node
onready var oPlayer = get_node(Nodelist.oPlayer)
onready var oChunkUnloader = get_node(Nodelist.oChunkUnloader)
onready var oWorldGen = get_node(Nodelist.oWorldGen)
onready var oOccluderManager = get_node(Nodelist.oOccluderManager)

var VIEW_DISTANCE = settings.VIEW_DISTANCE
var CHUNK_SIZE_X = settings.CHUNK_SIZE_X
var CHUNK_SIZE_Y = settings.CHUNK_SIZE_Y
var CHUNK_SIZE_Z = settings.CHUNK_SIZE_Z
var CHUNK_SIZE = Vector3(CHUNK_SIZE_X, CHUNK_SIZE_Y, CHUNK_SIZE_Z)

# The top half of chunks in Minecraft are empty: https://minecraft.gamepedia.com/Altitude
var MOUNTAIN_PEAK = floor(CHUNK_SIZE_Y * 0.50) #Position of maximum mountain peaks within chunk height
var GROUND_LEVEL  = floor(CHUNK_SIZE_Y * 0.25) #Position of ground level within chunk height

var chunkMap = {}
var locationsInView = []
var placeAt = []
var removeFrom = []
var playerChunkPos = null

func _process(delta):
	playerOnChunk()
	processChunks()

func playerOnChunk():
	var newLoc = Vector3(oPlayer.translation.x/CHUNK_SIZE_X, 0 ,oPlayer.translation.z/CHUNK_SIZE_Z).floor()
	if newLoc != playerChunkPos:
		playerChunkPos = newLoc
		listLocations(playerChunkPos)

func listLocations(center):
	var previousLocationsInView = locationsInView.duplicate()
	locationsInView.clear()
	
	# Update a list called "placeAt" which consists of positions to create new chunks at.
	for x in range (center.x-VIEW_DISTANCE, 1+center.x+VIEW_DISTANCE):
		for z in range (center.z-VIEW_DISTANCE, 1+center.z+VIEW_DISTANCE):
			var chunkSpace = Vector3(x, 0, z)
			if chunkSpace.distance_to(Vector3(playerChunkPos.x,0,playerChunkPos.z)) < VIEW_DISTANCE:
				locationsInView.append(chunkSpace)
				if chunkMap.has(chunkSpace) == false:
					placeAt.append(chunkSpace)
				#if position is currently on the "removeFrom" list, then remove from that list.
				var check = removeFrom.find(chunkSpace)
				if check != -1:
					removeFrom.remove(check)
	
	# Update a list called "removeFrom" which consists of positions to remove chunks from.
	for i in previousLocationsInView.size():
		var chunkSpace = previousLocationsInView[i]
		if chunkMap.has(chunkSpace) == true and locationsInView.has(chunkSpace) == false:
			removeFrom.append(chunkSpace)
		#if position is currently on the "placeAt" list, then remove from that list.
		var check = placeAt.find(chunkSpace) 
		if check != -1:
			placeAt.remove(check)
	
	placeAt.sort_custom(self,"sortByDistanceToPlayer")
	removeFrom.sort_custom(self,"sortByDistanceToPlayer")

func sortByDistanceToPlayer(a, b):
	return a.distance_to(playerChunkPos) < b.distance_to(playerChunkPos)

func processChunks():
	if oWorldGen.currentlyInUse == false and placeAt.empty() == false:
			
			if removeFrom.empty() == false:
				var fromSpace = removeFrom.back() #most distant chunkpos
				if chunkMap.has(fromSpace) == true:
					var id = chunkMap[fromSpace]
					if id.processingBlocks == false: #this check fixes a rare thread crash.
						removeFrom.pop_back() #remove most distant chunkpos
						oChunkUnloader.addToFreeQueue(id) #queue chunk for removal
						chunkMap.erase(fromSpace) #remove from chunkMap
						
						if settings.occludeCaveLight == true:
							oOccluderManager.removeStrandedOccluders(fromSpace)
							oOccluderManager.spawnOccluder(fromSpace)
			
			var toSpace = placeAt.pop_front() #Closest chunkpos
			if chunkMap.has(toSpace) == false:
				oWorldGen.currentlyInUse = true
				spawnChunk(toSpace)
				
				if settings.occludeCaveLight == true:
					oOccluderManager.surroundWithOccluders(toSpace)

func spawnChunk(chunkSpace):
	var id = preload("res://spawn/Chunk.tscn").instance()
	chunkMap[chunkSpace] = id #Write to chunkMap
	add_child(id)
	id.translation = chunkSpace*CHUNK_SIZE
	id.justPlaced()

func getChunk(worldPos):
	var chunkSpace = (worldPos/CHUNK_SIZE).floor()
	if chunkMap.has(chunkSpace):
		var chunkID = chunkMap[chunkSpace]
		if chunkID.processingBlocks == false: #Only get chunks that are completely done generating. Otherwise return null.
			return chunkMap[chunkSpace]
	return null
