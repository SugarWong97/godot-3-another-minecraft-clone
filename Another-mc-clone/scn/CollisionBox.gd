extends CollisionShape
onready var oPlayer = get_node(Nodelist.oPlayer)

func _ready():
	shape.extents = Vector3(oPlayer.PLAYER_WIDTH*0.5,oPlayer.PLAYER_HEIGHT*0.5,oPlayer.PLAYER_WIDTH*0.5)
	translation = Vector3(0,-(oPlayer.PLAYER_EYE_HEIGHT*0.50),0)
