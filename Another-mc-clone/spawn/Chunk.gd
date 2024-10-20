extends Spatial
onready var oPlayer = get_node(Nodelist.oPlayer)
onready var oWorldChunks = get_node(Nodelist.oWorldChunks)
onready var oWorldGen = get_node(Nodelist.oWorldGen)
onready var oOccluderManager = get_node(Nodelist.oOccluderManager)
onready var oWorldInteract = get_node(Nodelist.oWorldInteract)
onready var oMeshInstance = $MeshInstance

var processingBlocks = true
var blockMap = [] #contains arrays within arrays, the array index determines the block position, the final value inside determines the block type (null is empty)
var meshInfo = [] #The position of each mesh in the ArrayMesh and the number of its sides rendered
var meshArrays = [] #ArrayMesh
var totalFaceCount = 0
var neighbourChunks = [null,null,null,null]
var locationInChunkSpace

func justPlaced():
	locationInChunkSpace = Vector3(translation.x/oWorldChunks.CHUNK_SIZE_X, translation.y/oWorldChunks.CHUNK_SIZE_Y, translation.z/oWorldChunks.CHUNK_SIZE_Z).floor()
	oWorldGen.begin(self)

func deleteSelf():
	queue_free()

func threadCompleted(returnedBlockMap, returnedMeshInfo, returnedMeshArrays, returnedTotalFaceCount, returnedGeneratedMesh, returnedSurroundingBlockMaps):
	meshInfo = returnedMeshInfo
	meshArrays = returnedMeshArrays
	totalFaceCount = returnedTotalFaceCount
	oMeshInstance.mesh = returnedGeneratedMesh
	blockMap = returnedBlockMap
	oWorldGen.currentlyInUse = false
	
	print('Total time: '+str(OS.get_ticks_msec()-oWorldGen.CODETIME_START)+'ms')
	
	processingBlocks = false #don't put this in finalize(), because finalize can be called from elsewhere.
	
	if settings.occludeCaveLight == true and oOccluderManager.occluderMap.has(locationInChunkSpace):
		oOccluderManager.removeOccluder(locationInChunkSpace)

func finalize():
	var generateMesh = ArrayMesh.new()
	
	var createMeshArrays = oWorldGen.putMeshArrayInPoolArray(meshArrays)
	generateMesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, createMeshArrays)
	generateMesh.surface_set_material(0,oWorldGen.TERRAIN_MAT)
	oMeshInstance.mesh = generateMesh

func addBlock(pos):
	var CODETIME_START = OS.get_ticks_msec()
	var x = pos.x
	var y = pos.y
	var z = pos.z
	var value = oPlayer.BLOCK_SELECTION
	blockMap[x][y][z] = value
	neighbourChunks = oWorldGen.establishNeighbours(translation) #needs to be called before faceLoop so values past the edge of the chunk can be obtained
	totalFaceCount += oWorldGen.faceLoop(pos,value,totalFaceCount,blockMap,neighbourChunks,meshArrays,meshInfo)
	updateSurrounding(pos)
	finalize() #update the chunk's mesh to reflect changes
	print('Addblock time: '+str(OS.get_ticks_msec()-CODETIME_START)+'ms')

func removeBlock(pos):
	var CODETIME_START = OS.get_ticks_msec()
	blockMap[pos.x][pos.y][pos.z] = oWorldGen.EMPTY
	neighbourChunks = oWorldGen.establishNeighbours(translation)
	clearBlockMesh(pos)
	updateSurrounding(pos)
	finalize()
	print('Removeblock time: '+str(OS.get_ticks_msec()-CODETIME_START)+'ms')

func updateSurrounding(pos): #local position within chunk
	# 1. Surrounding cubes (and self) are completely cleared.
	# 2. Surrounding cubes have their faces completely restructured. (except for selected block which remains cleared)
	
	var direction = global.direction
	for i in 6: #Delete surrounding block meshes (entire cubes are being deleted, this could be better optimized to remove only the specific sides)
		var surroundingPos = pos+direction[i]
		var value = getBlock(surroundingPos)
		if value:
			if isBlockInsideChunk(surroundingPos):
				clearBlockMesh(surroundingPos) #clear all faces of that block
				totalFaceCount += oWorldGen.faceLoop(surroundingPos,value,totalFaceCount,blockMap,neighbourChunks,meshArrays,meshInfo)
			else: #Block is outside of chunk, so get the chunk ID that contains the block, then update that chunk.
				var lookAtWorldPos = surroundingPos+translation
				var id = oWorldChunks.getChunk(lookAtWorldPos)
				if id:
					var localPosInOutsideChunk = oWorldInteract.worldPosToLocalPos(lookAtWorldPos)
					id.updateBlock(localPosInOutsideChunk,value)

func updateBlock(pos,value):
	#clear all faces of that block
	clearBlockMesh(pos)
	#re-add all faces of that block
	neighbourChunks = oWorldGen.establishNeighbours(translation)
	totalFaceCount += oWorldGen.faceLoop(pos,value,totalFaceCount,blockMap,neighbourChunks,meshArrays,meshInfo)
	#update the block's chunk's mesh to reflect changes
	finalize()

func clearBlockMesh(pos):
	#temporary variable is required in order to edit the values of these arrays.
	var cubePosition = meshInfo[oWorldGen.ARRAY_CUBE_POSITION]
	var sideCount = meshInfo[oWorldGen.ARRAY_SIDE_COUNT]
	var tmpMeshIndex = meshArrays[Mesh.ARRAY_INDEX]
	var tmpMeshVertex = meshArrays[Mesh.ARRAY_VERTEX]
	var tmpMeshTexUV = meshArrays[Mesh.ARRAY_TEX_UV]
	var tmpMeshNormal = meshArrays[Mesh.ARRAY_NORMAL]
	
	# Finds block coordinates inside the array and gets the array position (atIndex)
	var atIndex = -1
	for i in cubePosition.size():
		if cubePosition[i] == pos:
			atIndex = i
	
	if atIndex != -1:
		var goToArrayPosition = 0
		for i in atIndex:
			goToArrayPosition += sideCount[i]*4 #adds up all the arraymesh sides to get to the correct position
		
		#Remove the mesh faces
		for i in sideCount[atIndex]: #For each side of the chosen cube
			totalFaceCount -= 1
			for O in 6: #Delete each of the 6 indices which make up that side.
				tmpMeshIndex.remove(tmpMeshIndex.size()-1) #Index numbers use a repeating pattern so just remove the items at the end of the array
			for O in 4: #Delete each of the 4 vertices which make up that side. (also UV and normal)
				tmpMeshVertex.remove(goToArrayPosition)
				tmpMeshTexUV.remove(goToArrayPosition)
				tmpMeshNormal.remove(goToArrayPosition)
		#Remove the block info.
		cubePosition.remove(atIndex)
		sideCount.remove(atIndex)

	meshInfo[oWorldGen.ARRAY_CUBE_POSITION] = cubePosition
	meshInfo[oWorldGen.ARRAY_SIDE_COUNT] = sideCount
	meshArrays[Mesh.ARRAY_INDEX] = tmpMeshIndex
	meshArrays[Mesh.ARRAY_VERTEX] = tmpMeshVertex
	meshArrays[Mesh.ARRAY_TEX_UV] = tmpMeshTexUV
	meshArrays[Mesh.ARRAY_NORMAL] = tmpMeshNormal

func getBlock(pos): #Local position in chunk
	if !isBlockInsideChunk(pos): #Is position inside chunk?
		return oWorldInteract.worldBlock(pos+translation) #then retrieve the value of the block that is outside of the chunk
	return blockMap[pos.x][pos.y][pos.z] #Block map in chunk (local coordinates)

func isBlockInsideChunk(pos): #Local position in chunk
	if pos.x < 0 or pos.x > oWorldChunks.CHUNK_SIZE_X-1 or pos.y < 0 or pos.y > oWorldChunks.CHUNK_SIZE_Y-1 or pos.z < 0 or pos.z > oWorldChunks.CHUNK_SIZE_Z-1:
		return false
	else:
		return true
