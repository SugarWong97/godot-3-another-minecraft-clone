extends Node
onready var oWorldChunks = get_node(Nodelist.oWorldChunks)
onready var oPlayer = get_node(Nodelist.oPlayer)
onready var oWorldInteract = get_node(Nodelist.oWorldInteract)
const START_FACING_DIRECTION = Vector3(0,0,0)
var spawnPos = Vector3()

func _ready():
	spawnPos.x = floor(oWorldChunks.CHUNK_SIZE_X*0.5) #Put player on center of chunk and center of block
	spawnPos.y = oWorldChunks.CHUNK_SIZE_Y-1 #Player's Y spawn is adjusted in process
	spawnPos.z = floor(oWorldChunks.CHUNK_SIZE_Z*0.5) #Put player on center of chunk and center of block

func _process(delta):
	var chunkID = oWorldChunks.getChunk(spawnPos)
	if chunkID != null:
		while true:
			if !oWorldInteract.worldBlock(spawnPos):
				spawnPos.y -= 1
			else:
				break
		
		oPlayer.rotation_degrees.y = START_FACING_DIRECTION.y
		oPlayer.oCamera.rotation_degrees.x = START_FACING_DIRECTION.x
		oPlayer.translation = Vector3(spawnPos.x+0.5, spawnPos.y, spawnPos.x+0.5) #Put player on center of block
		oPlayer.translation.y += 1.15+oPlayer.PLAYER_HEIGHT #adjust to prevent player from spawning inside a block
		set_process(false)
