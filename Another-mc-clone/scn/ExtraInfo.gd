extends Label
onready var oPlayer = get_node(Nodelist.oPlayer)
onready var oCamera = get_node(Nodelist.oCamera)
onready var oBlockSelector = get_node(Nodelist.oBlockSelector)

var displayInfo = false

func _ready():
	set_process(displayInfo)

func _input(event):
	if Input.is_action_just_pressed('debug1'):
		displayInfo = !displayInfo
		set_process(displayInfo)

func _process(delta):
	var cx = 'x '+str(oPlayer.translation.x)
	var cy = 'y '+str(oPlayer.translation.y)
	var cz = 'z '+str(oPlayer.translation.z)
	
	var textline1 = 'Draw distance : '+str(oCamera.far) + '\n'
	var textline2 = compass() + '\n'
	var textline3 = cx+'\n'
	var textline4 = cy+'\n'
	var textline5 = cz+'\n'
	var textline6 = str(oBlockSelector.translation)+'\n'
	var textline7 = 'Vertex attributes '+str(get_tree().get_root().get_render_info(Viewport.RENDER_INFO_VERTICES_IN_FRAME))+'\n'
	
	text = textline1+textline2+textline3+textline4+textline5+textline6+textline7

func compass():
	var degrees = fposmod(oCamera.rotation_degrees.y+180.0, 360.0)
	if degrees >= 45 and degrees < 135:
		return 'East'
	if degrees >= 135 and degrees < 225:
		return 'North'
	if degrees >= 225 and degrees < 315:
		return 'West'
	if degrees >= 315 or degrees < 45:
		return 'South'
