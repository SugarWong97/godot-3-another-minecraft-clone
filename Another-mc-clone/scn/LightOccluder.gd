extends Spatial
onready var oWorldGen = get_node(Nodelist.oWorldGen)
onready var oMesh = $Mesh

func _ready():
	var occluderHeight = oWorldGen.MOUNTAIN_PEAK
	var size = Vector3(oWorldGen.CHUNK_SIZE_X,occluderHeight,oWorldGen.CHUNK_SIZE_Z)
	oMesh.translation = size
	oMesh.scale = size
