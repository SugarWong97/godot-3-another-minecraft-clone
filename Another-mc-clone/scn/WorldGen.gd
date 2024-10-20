extends Node
onready var oCubeData = get_node(Nodelist.oCubeData)
onready var oTextureAtlas = get_node(Nodelist.oTextureAtlas)
onready var oWorldInteract = get_node(Nodelist.oWorldInteract)
onready var oWorldChunks = get_node(Nodelist.oWorldChunks)

onready var CHUNK_SIZE_X = oWorldChunks.CHUNK_SIZE_X
onready var CHUNK_SIZE_Y = oWorldChunks.CHUNK_SIZE_Y
onready var CHUNK_SIZE_Z = oWorldChunks.CHUNK_SIZE_Z
onready var MOUNTAIN_PEAK = oWorldChunks.MOUNTAIN_PEAK
onready var GROUND_LEVEL = oWorldChunks.GROUND_LEVEL
onready var blockFaces = oTextureAtlas.blockFaces

onready var chunkDir = [Vector3(0,0,-CHUNK_SIZE_Z), Vector3(0,0,CHUNK_SIZE_Z), Vector3(CHUNK_SIZE_X,0,0), Vector3(-CHUNK_SIZE_X,0,0), Vector3(0,CHUNK_SIZE_Y,0), Vector3(0,-CHUNK_SIZE_Y,0)] # N,S,E,W,T,B
var TERRAIN_MAT = preload("res://mat/terrainMat.tres")

var NOISE = OpenSimplexNoise.new()
var thread = Thread.new()
var semaphore = Semaphore.new()
var chunkID
var chunkPos
var CODETIME_START
var currentlyInUse = false
var cavesOn = settings.cavesOn

enum {ARRAY_CUBE_POSITION = 0, ARRAY_SIDE_COUNT = 1}
const EMPTY = null # Using null instead of 0 because resizing arrays creates null entries.
enum {
	GRASS = 1
	DIRT = 2
	STONE = 3
}

func _ready():
	noiseSettings()
	thread.start(self, "threadedGeneration") #Begin running a thread that never finishes.
	CODETIME_START = OS.get_ticks_msec()

func noiseSettings():
	#randomize() #disabled for performance comparisons
	NOISE.seed = randi()
	NOISE.octaves = 4
	NOISE.period = 20
	NOISE.persistence = 2
	NOISE.lacunarity = 1.25

func begin(passChunk):
	chunkID = passChunk
	chunkPos = passChunk.translation
	semaphore.post() # Make the thread process.

func threadedGeneration(userdata):
	while true: # Thread is constantly running, never finishes.
		semaphore.wait() # Thread remains idle until posted.
		
		var CODETIME_ONECHUNK = OS.get_ticks_msec()
		
		##############
		# Set values #
		##############
		
		var newBlockMap = oCubeData.baseBlockMap.duplicate(true) # Good optimization when there's no caves
		var alteredLayerY = []
		var countFilled = 0
		var bottomPos = GROUND_LEVEL
		if cavesOn == true:
			bottomPos = 0
		
		#var CODETIME_BLOCKMAP = OS.get_ticks_msec()
		
		for y in range (bottomPos, MOUNTAIN_PEAK): #Y positions above and below this have already been set to EMPTY, with baseBlockMap
			var yLayerCount = countFilled
			for x in range(0, CHUNK_SIZE_X):
				for z in range(0, CHUNK_SIZE_Z):
					var value = worldGen(chunkPos+Vector3(x,y,z))
					if value:
						newBlockMap[x][y][z] = value
						countFilled += 1
			if yLayerCount != countFilled:
				alteredLayerY.append(y)
		
		#print('BlockMap time: '+str(OS.get_ticks_msec()-CODETIME_BLOCKMAP)+'ms')
		
		##################
		# Set mesh sides #
		##################
		
		#var CODETIME_MESHFACE = OS.get_ticks_msec()
		
		var newMeshInfo = []
		newMeshInfo.resize(2)
		newMeshInfo[ARRAY_CUBE_POSITION] = []
		newMeshInfo[ARRAY_SIDE_COUNT] = []
		var newMeshArrays = []
		newMeshArrays.resize(Mesh.ARRAY_MAX)
		newMeshArrays[Mesh.ARRAY_INDEX] = []
		newMeshArrays[Mesh.ARRAY_VERTEX] = []
		newMeshArrays[Mesh.ARRAY_TEX_UV] = []
		newMeshArrays[Mesh.ARRAY_NORMAL] = []
		
		var neighbourChunks = establishNeighbours(chunkPos)
		
		var newTotalFaceCount = 0
		for y in range (0, MOUNTAIN_PEAK):
			if alteredLayerY.has(y):
				for x in CHUNK_SIZE_X:
					for z in CHUNK_SIZE_Z:
						var value = newBlockMap[x][y][z]
						if value:
							newTotalFaceCount += faceLoop(Vector3(x,y,z),value,newTotalFaceCount,newBlockMap,neighbourChunks,newMeshArrays,newMeshInfo)
		
		#print('Mesh Face time: '+str(OS.get_ticks_msec()-CODETIME_MESHFACE)+'ms')
		
		var createMeshArrays = putMeshArrayInPoolArray(newMeshArrays)
		
		var newGeneratedMesh = ArrayMesh.new()
		newGeneratedMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, createMeshArrays)
		newGeneratedMesh.surface_set_material(0,TERRAIN_MAT)
		
		print('Single chunk time: '+str(OS.get_ticks_msec()-CODETIME_ONECHUNK)+'ms')
		chunkID.call_deferred('threadCompleted', newBlockMap, newMeshInfo, newMeshArrays, newTotalFaceCount, newGeneratedMesh, neighbourChunks)

func worldGen(worldPos):
	var ypos = worldPos.y
	if cavesOn == true and ypos <= GROUND_LEVEL:
		if NOISE.get_noise_3dv(worldPos) < 0:
			return STONE
		if ypos == GROUND_LEVEL:
			return STONE
		if ypos == 0:
			return STONE
		return EMPTY
	else:
		var percentage = abs(NOISE.get_noise_2dv(Vector2(worldPos.x,worldPos.z))) #abs() makes the value 0.0 - 1.0. Instead of -1.0 to 1.0.
		var terrainHeight = floor(lerp(GROUND_LEVEL, MOUNTAIN_PEAK, percentage))
		if ypos < terrainHeight:
			return DIRT
		elif ypos == terrainHeight:
			return GRASS
		return EMPTY

func establishNeighbours(pos):
	var neighbours = []
	for i in 4:
		var chunkNear = oWorldChunks.getChunk(pos+chunkDir[i])
		if chunkNear:
			neighbours.append(chunkNear.blockMap)
		else:
			neighbours.append(null)
	return neighbours

#The reason there's so many arguments is because Chunks call these functions too, when you add and remove blocks from them.
func faceLoop(pos,value,totalFaceCount,blockMap,neighbourChunks,meshArrays,meshInfo):
	var x = pos.x
	var y = pos.y
	var z = pos.z
	var countSides = 0
	if not getLocalBlockNorth(x,y,z-1, blockMap, neighbourChunks):
		addFace(pos,0,value,meshArrays, totalFaceCount+countSides)
		countSides += 1
	if not getLocalBlockSouth(x,y,z+1, blockMap, neighbourChunks):
		addFace(pos,1,value,meshArrays, totalFaceCount+countSides)
		countSides += 1
	if not getLocalBlockEast(x+1,y,z, blockMap, neighbourChunks):
		addFace(pos,2,value,meshArrays, totalFaceCount+countSides)
		countSides += 1
	if not getLocalBlockWest(x-1,y,z, blockMap, neighbourChunks):
		addFace(pos,3,value,meshArrays, totalFaceCount+countSides)
		countSides += 1
	if not getLocalBlockTop(x,y+1,z, blockMap):
		addFace(pos,4,value,meshArrays, totalFaceCount+countSides)
		countSides += 1
	if not getLocalBlockBottom(x,y-1,z, blockMap):
		addFace(pos,5,value,meshArrays, totalFaceCount+countSides)
		countSides += 1
	if countSides > 0:
		meshInfo[ARRAY_CUBE_POSITION].append(pos) #blockmap position for this cube mesh
		meshInfo[ARRAY_SIDE_COUNT].append(countSides) #number of sides being rendered at this blockmap position
	return countSides

func getLocalBlockNorth(x,y,z,blockMap,neighbourChunks):
	if z < 0: #Is position outside chunk?
		if neighbourChunks[0]:
			#then retrieve the value of the block that is outside of the chunk
			var localPos = oWorldInteract.worldPosToLocalPos(Vector3(x,y,z)+chunkPos)
			return neighbourChunks[0][localPos.x][localPos.y][localPos.z]
		return worldGen(Vector3(x,y,z)+chunkPos)
	return blockMap[x][y][z]

func getLocalBlockSouth(x,y,z,blockMap,neighbourChunks):
	if z > CHUNK_SIZE_Z-1: #Is position outside chunk?
		if neighbourChunks[1]:
			#then retrieve the value of the block that is outside of the chunk
			var localPos = oWorldInteract.worldPosToLocalPos(Vector3(x,y,z)+chunkPos)
			return neighbourChunks[1][localPos.x][localPos.y][localPos.z]
		return worldGen(Vector3(x,y,z)+chunkPos)
	return blockMap[x][y][z]

func getLocalBlockEast(x,y,z,blockMap,neighbourChunks):
	if x > CHUNK_SIZE_X-1: #Is position outside chunk?
		if neighbourChunks[2]:
			#then retrieve the value of the block that is outside of the chunk
			var localPos = oWorldInteract.worldPosToLocalPos(Vector3(x,y,z)+chunkPos)
			return neighbourChunks[2][localPos.x][localPos.y][localPos.z]
		return worldGen(Vector3(x,y,z)+chunkPos)
	return blockMap[x][y][z]

func getLocalBlockWest(x,y,z,blockMap,neighbourChunks):
	if x < 0: #Is position outside chunk?
		if neighbourChunks[3]:
			#then retrieve the value of the block that is outside of the chunk
			var localPos = oWorldInteract.worldPosToLocalPos(Vector3(x,y,z)+chunkPos)
			return neighbourChunks[3][localPos.x][localPos.y][localPos.z]
		return worldGen(Vector3(x,y,z)+chunkPos)
	return blockMap[x][y][z]

func getLocalBlockTop(x,y,z,blockMap):
	if y > CHUNK_SIZE_Y-1: #Is position outside chunk?
		return GRASS
	return blockMap[x][y][z]

func getLocalBlockBottom(x,y,z,blockMap):
	if y < 0: #Is position outside chunk?
		return STONE
	return blockMap[x][y][z]

func addFace(pos,side,value,meshArrays,totalFaceCount):
	
	var sideArray = oCubeData.vertex[side]
	meshArrays[Mesh.ARRAY_VERTEX].append_array([
		pos + sideArray[0],
		pos + sideArray[1],
		pos + sideArray[2],
		pos + sideArray[3],
	])
	
	var idx = totalFaceCount*4
	meshArrays[Mesh.ARRAY_INDEX].append_array([
		0+idx, 1+idx, 3+idx, #012
		3+idx, 1+idx, 2+idx, #023
	])
	
	meshArrays[Mesh.ARRAY_TEX_UV].append_array(oTextureAtlas.texUV[blockFaces[value][side]])
	meshArrays[Mesh.ARRAY_NORMAL].append_array(oCubeData.normal[side])

func putMeshInfoInPoolArray(newMeshInfo):
	var createMeshInfo = []
	createMeshInfo.resize(2)
	createMeshInfo[ARRAY_CUBE_POSITION] = PoolVector3Array(newMeshInfo[ARRAY_CUBE_POSITION])
	createMeshInfo[ARRAY_SIDE_COUNT] = PoolIntArray(newMeshInfo[ARRAY_SIDE_COUNT])
	return createMeshInfo
func putMeshArrayInPoolArray(newMeshArrays):
	var createMeshArrays = []
	createMeshArrays.resize(Mesh.ARRAY_MAX)
	createMeshArrays[Mesh.ARRAY_INDEX] = PoolIntArray(newMeshArrays[Mesh.ARRAY_INDEX])
	createMeshArrays[Mesh.ARRAY_VERTEX] = PoolVector3Array(newMeshArrays[Mesh.ARRAY_VERTEX])
	createMeshArrays[Mesh.ARRAY_TEX_UV] = PoolVector2Array(newMeshArrays[Mesh.ARRAY_TEX_UV])
	createMeshArrays[Mesh.ARRAY_NORMAL] = PoolVector3Array(newMeshArrays[Mesh.ARRAY_NORMAL])
	return createMeshArrays
