extends Position2D

func _process(delta):
	match Input.get_mouse_mode():
		Input.MOUSE_MODE_CAPTURED:
			position = global.viewCenter
		Input.MOUSE_MODE_CONFINED:
			position = get_global_mouse_position()
