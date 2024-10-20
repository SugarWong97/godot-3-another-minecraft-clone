extends Node
onready var oWorldGen = get_node(Nodelist.oWorldGen)
onready var oWorldChunks = get_node(Nodelist.oWorldChunks)
enum {North,South,East,West,Top,Bottom}
var vertex = [0,1,2,3,4,5]
var texUV = [0,1,2,3,4,5]
var normal = [0,1,2,3,4,5]
var baseBlockMap = []

func _ready():
	var STONE = oWorldGen.STONE
	var GROUND_LEVEL = oWorldChunks.GROUND_LEVEL
	var CHUNK_SIZE_X = oWorldChunks.CHUNK_SIZE_X
	var CHUNK_SIZE_Y = oWorldChunks.CHUNK_SIZE_Y
	var CHUNK_SIZE_Z = oWorldChunks.CHUNK_SIZE_Z
	
	# Base blockmap that is used as a starting point for chunks created in WorldGen.
	baseBlockMap.resize(CHUNK_SIZE_X) # Create X-dimension
	for x in CHUNK_SIZE_X:
		baseBlockMap[x] = []
		baseBlockMap[x].resize(CHUNK_SIZE_Y) # Create Y-dimension
		for y in CHUNK_SIZE_Y:
			baseBlockMap[x][y] = []
			baseBlockMap[x][y].resize(CHUNK_SIZE_Z) # Create Z-dimension
	
	if oWorldGen.cavesOn == false:
		for y in range (0, GROUND_LEVEL):
			for x in range (0, CHUNK_SIZE_X):
				for z in range (0, CHUNK_SIZE_Z):
					baseBlockMap[x][y][z] = STONE
	
	vertex[North] = [
		Vector3(1, 1, 0),
		Vector3(0, 1, 0),
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
	]
	vertex[South] = [
		Vector3(0, 1, 1),
		Vector3(1, 1, 1),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
	]
	vertex[East] = [
		Vector3(1, 1, 1),
		Vector3(1, 1, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
	]
	vertex[West] = [
		Vector3(0, 1, 0),
		Vector3(0, 1, 1),
		Vector3(0, 0, 1),
		Vector3(0, 0, 0),
	]
	vertex[Top] = [
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1),
	]
	vertex[Bottom] = [
		Vector3(1, 0, 0),
		Vector3(0, 0, 0),
		Vector3(0, 0, 1),
		Vector3(1, 0, 1),
	]
	
	normal[North] = [
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
		Vector3(0, 0, -1),
	]
	normal[South] = [
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 0, 1),
	]
	normal[East] = [
		Vector3(1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 0),
	]
	normal[West] = [
		Vector3(-1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(-1, 0, 0),
	]
	normal[Top] = [
		Vector3(0, 1, 0),
		Vector3(0, 1, 0),
		Vector3(0, 1, 0),
		Vector3(0, 1, 0),
	]
	normal[Bottom] = [
		Vector3(0, -1, 0),
		Vector3(0, -1, 0),
		Vector3(0, -1, 0),
		Vector3(0, -1, 0),
	]
