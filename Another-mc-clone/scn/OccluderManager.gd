extends Node
onready var oWorldChunks = get_node(Nodelist.oWorldChunks)

var occluderScene = load("res://spawn/LightOccluder.tscn")
var occluderMap = {}

func surroundWithOccluders(cSpace):
	var direction = global.direction
	for i in 4:
		spawnOccluder(cSpace+direction[i])

func removeStrandedOccluders(cSpace):
	var direction = global.direction
	for i in 4:
		var cSpace2 = cSpace+direction[i]
		if occluderMap.has(cSpace2) == true and oWorldChunks.chunkMap.has(cSpace2) == false:
			var foundNearbyChunk = false
			for k in 4: #Look for nearby chunks to see whether this occluder is stranded or not
				if oWorldChunks.chunkMap.has(cSpace2+direction[k]) == true:
					foundNearbyChunk = true
			if foundNearbyChunk == false:
				removeOccluder(cSpace2) #It is stranded, so remove it.

func spawnOccluder(cSpace):
	if oWorldChunks.chunkMap.has(cSpace) == false and occluderMap.has(cSpace) == false:
		var id = occluderScene.instance()
		occluderMap[cSpace] = id # Write to occluderMap
		add_child(id)
		id.translation = cSpace*oWorldChunks.CHUNK_SIZE

func removeOccluder(cSpace):
	occluderMap[cSpace].queue_free()
	occluderMap.erase(cSpace)
