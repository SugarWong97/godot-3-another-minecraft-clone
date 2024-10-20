extends OmniLight
const SMOOTH_MOVEMENT = 0.0333 #0.333 #Light moves from position to position smoothly, so there is less sudden flashes between looking at distant tile and close tile
var desiredPos = Vector3()

func _process(delta):
	translation = lerp(translation,desiredPos,SMOOTH_MOVEMENT)
