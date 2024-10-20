extends Node
onready var viewCenter = get_viewport().size / 2
var direction = [Vector3(0,0,-1), Vector3(0,0,1), Vector3(1,0,0), Vector3(-1,0,0), Vector3(0,1,0), Vector3(0,-1,0)] # N,S,E,W,T,B
var FPScounter = preload('res://scn/FPScounter.tscn').instance()
var debugdraw = 0
var layer = {}

func _ready():
	get_tree().get_root().call_deferred("add_child",FPScounter)
	OS.vsync_enabled = false
	collisionLayers()

func _input(event):
	if Input.is_action_just_pressed("debug_restart_game"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed('debug_exit_game'):
		get_tree().quit()
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	
	if Input.is_action_just_pressed('debug3'):
		debugdraw += 1
		if debugdraw == 3:
			debugdraw = 0
		match debugdraw:
			0: get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_DISABLED)
			1: get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_UNSHADED)
			2: get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_OVERDRAW)

func collisionLayers():
	for i in range(1, 21):
		var nameLayer = ProjectSettings.get_setting(str("layer_names/3d_physics/layer_", i))
		if not nameLayer:
			nameLayer = str("Layer ", i)
		layer[nameLayer] = pow(2, i-1)
