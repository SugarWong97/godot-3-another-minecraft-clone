extends KinematicBody
onready var oCamera = get_node(Nodelist.oCamera)
onready var oBlockSelector = get_node(Nodelist.oBlockSelector)
onready var oBlockPlacer = get_node(Nodelist.oBlockPlacer)
onready var oSelectorLight = get_node(Nodelist.oSelectorLight)
onready var oTimerJumpCooldown = get_node(Nodelist.oTimerJumpCooldown)
onready var oCollisionBox = get_node(Nodelist.oCollisionBox)
onready var oWorldGen = get_node(Nodelist.oWorldGen)
onready var oWorldInteract = get_node(Nodelist.oWorldInteract)
onready var oCubeCollision = get_node(Nodelist.oCubeCollision)

const walkSpeed = 8 #4.317 # Distance to travel in 1 second in _process(delta)
const sprintSpeed = 50
const jumpForce = 10
const gravity = -12
const COLLISION_PRECISION = 0.05 #The smaller the number the closer the player will move to the wall edge, though requires more collision checks.
const PLAYER_HEIGHT = 1.8
const PLAYER_EYE_HEIGHT = 1.62
const PLAYER_WIDTH = 0.6
const reach = 10
var verticalMomentum = 0
var isOnFloor = false
var jumpCooldown = false
var bbox_left
var bbox_right
var bbox_top
var bbox_bottom
var bbox_front
var bbox_back
var BLOCK_SELECTION
var canPlace = true

func _ready():
	BLOCK_SELECTION = oWorldGen.DIRT
	updateBoundingBoxes()
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		oCamera.rotation_degrees.x -= event.relative.y * settings.mouseSensitivity
		oCamera.rotation_degrees.y -= event.relative.x * settings.mouseSensitivity
		oCamera.rotation_degrees.x = clamp(oCamera.rotation_degrees.x, -90, 90)

func _physics_process(delta):
	oWorldGen.TERRAIN_MAT.set_shader_param('player_position', translation)
	var speed = getSpeed()
	var direction = getDirection()
	var yAxisVelocity = 0
	yAxisVelocity = jumpingAndFalling(delta)
	var movement = Vector3(speed*direction.x, yAxisVelocity, speed*direction.z) * delta
	movement = blockMapCollision(movement)
	move_and_collide(movement) #move_and_slide(movement/delta)
	updateBoundingBoxes()
	ascendDescend()
	selectors()

func ascendDescend():
	if Input.is_action_just_released('move_ascend'):
		translation.y += 20
	if Input.is_action_just_released('move_descend'):
		translation.y -= 20

func selectors():
	var selectorVector = oCamera.transform.basis.z.normalized() * -reach
	var raycastData = oWorldInteract.raycastBlockmap(translation, translation+selectorVector)
	var diggerPos = null
	var placerPos = null
	if raycastData:
		var normal = raycastData["normal"]
		var collider = raycastData["collider"]
		match normal.abs().max_axis():
			Vector3.AXIS_X:
				normal.x = sign(normal.x)
				normal.z = 0
				normal.y = 0
			Vector3.AXIS_Y:
				normal.x = 0
				normal.y = sign(normal.y)
				normal.z = 0
			Vector3.AXIS_Z:
				normal.x = 0
				normal.y = 0
				normal.z = sign(normal.z)
		diggerPos = collider.translation
		placerPos = collider.translation + normal
	
	if diggerPos:
		oBlockSelector.visible = true
		oBlockSelector.translation = diggerPos
		if Input.is_action_pressed("cast"):
			oWorldInteract.removeBlockConditions(oBlockSelector.translation)
	else:
		oBlockSelector.visible = false #When no blocks are in reach, selector becomes invisible
	
	if placerPos:
		oBlockPlacer.translation = placerPos
		oSelectorLight.desiredPos = placerPos + Vector3(0.5,0.5,0.5)
		if Input.is_action_pressed("cast_alternate"):
			if oCubeCollision.detect(global.layer["Player"],placerPos).empty() == true:
				oWorldInteract.addBlockConditions(placerPos)
	else:
		oSelectorLight.desiredPos = (translation+selectorVector).floor() + Vector3(0.5,0.5,0.5)

func jumpingAndFalling(delta):
	if Input.is_action_pressed('jump') and isOnFloor == true and jumpCooldown == false:
		verticalMomentum = jumpForce
	
	if verticalMomentum > gravity:
		isOnFloor = false
		verticalMomentum += gravity * delta
	else: verticalMomentum = gravity
	
	return verticalMomentum

func getDirection():
	var dir = Vector3()
	dir.x = Input.get_action_strength('move_right') - Input.get_action_strength('move_left')
	dir.z = Input.get_action_strength('move_backwards') - Input.get_action_strength('move_forwards')
	dir = dir.rotated(Vector3(0,1,0), oCamera.rotation.y) #rotate movement vector along Y axis so strafing movement will be relative to the direction the camera is facing
	return dir.normalized() #normalize vector so player doesn't move faster diagonally

func getSpeed():
	if Input.is_action_pressed('sprint'):
		return sprintSpeed
	return walkSpeed

func updateBoundingBoxes():
	var extents = oCollisionBox.shape.extents
	bbox_right = (translation.x+extents.x) + oCollisionBox.translation.x
	bbox_left = (translation.x-extents.x) + oCollisionBox.translation.x
	bbox_top = (translation.y+extents.y) + oCollisionBox.translation.y
	bbox_bottom = (translation.y-extents.y) + oCollisionBox.translation.y
	bbox_back = (translation.z+extents.z) + oCollisionBox.translation.z
	bbox_front = (translation.z-extents.z) + oCollisionBox.translation.z

func blockMapCollision(movement):
	var addAxisToCheck = Vector3(0,0,0)
	if movement.z > 0: #South
		addAxisToCheck.z = checkAxisAgainstBlockMap(movement.z, Vector3.BACK, addAxisToCheck)
	elif movement.z < 0: #North
		addAxisToCheck.z = checkAxisAgainstBlockMap(movement.z, Vector3.FORWARD, addAxisToCheck)
	if movement.x > 0: #East
		addAxisToCheck.x = checkAxisAgainstBlockMap(movement.x, Vector3.RIGHT, addAxisToCheck)
	elif movement.x < 0: #West
		addAxisToCheck.x = checkAxisAgainstBlockMap(movement.x, Vector3.LEFT, addAxisToCheck)
	
	if movement.y > 0: #Top
		var wasThereChange = movement.y
		addAxisToCheck.y = checkAxisAgainstBlockMap(movement.y, Vector3.UP, addAxisToCheck)
		if addAxisToCheck.y != wasThereChange and isOnFloor == false: #Hit head when jumping
			jumpCooldown = true
			verticalMomentum = 0 #-verticalMomentum
			oTimerJumpCooldown.start() #The point of TimerJumpCooldown is when you hold jump in a cramped space (hit head on ceiling) you won't jump up and down super fast.
	elif movement.y < 0: #Bottom
		var wasThereChange = movement.y
		addAxisToCheck.y = checkAxisAgainstBlockMap(movement.y, Vector3.DOWN, addAxisToCheck)
		if addAxisToCheck.y != wasThereChange:
			isOnFloor = true
		else:
			isOnFloor = false
	return addAxisToCheck

func checkAxisAgainstBlockMap(axisTotalDistance, checkSide, addAxisToCheck):
	var cornerCheck1
	var cornerCheck2
	var cornerCheck3
	var cornerCheck4
	var centerCheck # Center check is needed because player collision box is larger than a block. When moving against one lone floating block all four corner checks can potentially miss it, which allows the player to move into the block (bad)
	match checkSide:
		Vector3.RIGHT: #East
			cornerCheck1 = Vector3(bbox_right, bbox_bottom, bbox_front)
			cornerCheck2 = Vector3(bbox_right, bbox_bottom, bbox_back)
			cornerCheck3 = Vector3(bbox_right, bbox_top, bbox_front)
			cornerCheck4 = Vector3(bbox_right, bbox_top, bbox_back)
			centerCheck = Vector3(bbox_right, (bbox_bottom+bbox_top)/2.0, (bbox_front+bbox_back)/2.0)
		Vector3.LEFT: #West
			cornerCheck1 = Vector3(bbox_left, bbox_bottom, bbox_front)
			cornerCheck2 = Vector3(bbox_left, bbox_bottom, bbox_back)
			cornerCheck3 = Vector3(bbox_left, bbox_top, bbox_front)
			cornerCheck4 = Vector3(bbox_left, bbox_top, bbox_back)
			centerCheck = Vector3(bbox_left, (bbox_bottom+bbox_top)/2.0, (bbox_front+bbox_back)/2.0)
		Vector3.UP: #Top
			cornerCheck1 = Vector3(bbox_left, bbox_top, bbox_back)
			cornerCheck2 = Vector3(bbox_right, bbox_top, bbox_front)
			cornerCheck3 = Vector3(bbox_right, bbox_top, bbox_back)
			cornerCheck4 = Vector3(bbox_left, bbox_top, bbox_front)
			centerCheck = Vector3((bbox_left+bbox_right)/2.0, bbox_top, (bbox_front+bbox_back)/2.0)
		Vector3.DOWN: #Bottom
			cornerCheck1 = Vector3(bbox_left, bbox_bottom, bbox_back)
			cornerCheck2 = Vector3(bbox_right, bbox_bottom, bbox_front)
			cornerCheck3 = Vector3(bbox_right, bbox_bottom, bbox_back)
			cornerCheck4 = Vector3(bbox_left, bbox_bottom, bbox_front)
			centerCheck = Vector3((bbox_left+bbox_right)/2.0, bbox_bottom, (bbox_front+bbox_back)/2.0)
		Vector3.FORWARD: #North
			cornerCheck1 = Vector3(bbox_left, bbox_bottom, bbox_front)
			cornerCheck2 = Vector3(bbox_left, bbox_top, bbox_front)
			cornerCheck3 = Vector3(bbox_right, bbox_bottom, bbox_front)
			cornerCheck4 = Vector3(bbox_right, bbox_top, bbox_front)
			centerCheck = Vector3((bbox_left+bbox_right)/2.0, (bbox_bottom+bbox_top)/2.0, bbox_front)
		Vector3.BACK: #South
			cornerCheck1 = Vector3(bbox_left, bbox_bottom, bbox_back)
			cornerCheck2 = Vector3(bbox_left, bbox_top, bbox_back)
			cornerCheck3 = Vector3(bbox_right, bbox_bottom, bbox_back)
			cornerCheck4 = Vector3(bbox_right, bbox_top, bbox_back)
			centerCheck = Vector3((bbox_left+bbox_right)/2.0, (bbox_bottom+bbox_top)/2.0, bbox_back)
	
	#The axis movements from previous script calls are added together, rather than set.
	cornerCheck1 += addAxisToCheck
	cornerCheck2 += addAxisToCheck
	cornerCheck3 += addAxisToCheck
	cornerCheck4 += addAxisToCheck
	centerCheck += addAxisToCheck
	
	var partDistance
	var checkAhead
	var checkAheadVector3
	var axis = checkSide.abs() #abs() is needed for axis variable so we don't multiply two negatives together (which gives a positive)
	var safeTravel = 0
	while axisTotalDistance != 0:
		partDistance = clamp(axisTotalDistance, -1, 1) #Don't check further than 1 block's space otherwise we risk skipping blocks.
		axisTotalDistance -= partDistance
		while partDistance != 0:
			checkAhead = partDistance
			checkAheadVector3 = Vector3(checkAhead+safeTravel,checkAhead+safeTravel,checkAhead+safeTravel) * axis
			if  oWorldInteract.worldBlock((centerCheck+checkAheadVector3).floor()) or \
				oWorldInteract.worldBlock((cornerCheck1+checkAheadVector3).floor()) or \
				oWorldInteract.worldBlock((cornerCheck2+checkAheadVector3).floor()) or \
				oWorldInteract.worldBlock((cornerCheck3+checkAheadVector3).floor()) or \
				oWorldInteract.worldBlock((cornerCheck4+checkAheadVector3).floor()):
				partDistance *= 0.5
				if abs(partDistance) < COLLISION_PRECISION: # Don't bother checking for distance smaller than this
					partDistance = 0
			else:
				safeTravel += partDistance
				partDistance = 0
	return safeTravel

func _on_BlockPlacer_body_shape_entered(body_id, body, body_shape, area_shape):
	canPlace = false
func _on_BlockPlacer_body_shape_exited(body_id, body, body_shape, area_shape):
	canPlace = true

func _on_PreventJump_timeout():
	jumpCooldown = false





#func raycastBlockMap(startPoint, endPoint, returnPreviousPositionToo):
#
#	var raycast = Vector3()
#	var raycastPreviousAxis = Vector3()
#	var raycastPreviousVector = Vector3()
#
#	var remainingVector = endPoint-startPoint
#
#	var clumsyIncrement = remainingVector.normalized()
#	var preciseIncrement = remainingVector.normalized()*0.025
#	var increment = clumsyIncrement
#	var preciseCheckMissesTheImpreciseBlock = false
#
#	var axisOrder = []
#	axisOrder.resize(3)
#	var indexAxis = 3
#	var preciseChecking = false #switches to precise after finding a block
#
#	var redoRearraged = 0
#
#	var clumsyLoops = 0
#	var preciseLoops = 0
#
#	while true:
#		# For one increment:
#		# Check all 3 axis of the increment, individually.
#		# Then change the order the axis are checked, the order is based on remaining distance to the target point.
#		# Then recheck the same increment with a shuffled order, twice, to see if another block comes up sooner. This fix is for when raycasting at the edges of a stranded block.
#		# Upon coming into contact with a block, switch to preciseIncrement and redo the previous increment.
#
#
#
#		if preciseChecking == true:
#			preciseLoops += 1
#		else:
#			clumsyLoops += 1
#
#		if indexAxis == 3:
#			indexAxis = 0
#			redoRearraged += 1
#			if redoRearraged != 1: # and preciseChecking == false
#				if redoRearraged == 3:
#					redoRearraged = 0
#				axisOrder.append(axisOrder.pop_front()) #shuffle order
#				raycast = raycastPreviousVector #rewind position
#				remainingVector = endPoint-(startPoint+raycast) #rewind position
#			else:
#				raycastPreviousVector = raycast #3 checks before collision (a whole vector)
#				var xP = 0; var yP = 0; var zP = 0
#				var compare = remainingVector.abs()
#				if compare.x >= compare.y:
#					xP += 1; yP -= 1
#				else:
#					xP -= 1; yP += 1
#				if compare.x >= compare.z:
#					xP += 1; zP -= 1
#				else:
#					xP -= 1; zP += 1
#				if compare.y >= compare.z:
#					yP += 1; zP -= 1
#				else:
#					yP -= 1; zP += 1
#				var sortDistances = [xP,yP,zP]
#				sortDistances.sort()
#				for i in sortDistances.size():
#					match sortDistances[i]:
#						xP: axisOrder[i] = 0
#						yP: axisOrder[i] = 1
#						zP: axisOrder[i] = 2
#
#		match axisOrder[indexAxis]:
#			0:
#				var part = increment.x
#				raycast.x += part
#				if abs(remainingVector.x) <= abs(increment.x):
#					remainingVector.x = 0
#				else:
#					remainingVector.x -= part
#			1:
#				var part = increment.y
#				raycast.y += part
#				if abs(remainingVector.y) <= abs(increment.y):
#					remainingVector.y = 0
#				else:
#					remainingVector.y -= part
#			2:
#				var part = increment.z
#				raycast.z += part
#				if abs(remainingVector.z) <= abs(increment.z):
#					remainingVector.z = 0
#				else:
#					remainingVector.z -= part
#
#		#print(oWorld.worldBlock((startPoint+raycast).floor()))
#		if oWorldInteract.worldBlock((startPoint+raycast).floor()):
#			if preciseChecking == false:
#				preciseChecking = true
#
#				increment = preciseIncrement
#				remainingVector = raycast-raycastPreviousVector #precise checks needs to be limited here, there's an edge case where the non-precise-found-block is not found by the precise check.
#				raycast = raycastPreviousVector #rewind position
#
#			else:
#				print('Block Found!')
#				print('precise loops = '+str(preciseLoops))
#				print('NON-precise loops = '+str(clumsyLoops))
#				return [startPoint+raycast, startPoint+raycastPreviousAxis] #Returns two values, a collision point and a pointBeforeCollision. Or returns [null,null] if no collision is found.
#
#		#print(preciseLoops)
#		#remaining
#		if remainingVector == Vector3(0,0,0):
#			if preciseChecking == true and preciseCheckMissesTheImpreciseBlock == false:
#				preciseCheckMissesTheImpreciseBlock = true
#				increment = clumsyIncrement #for the sake of optimization, but this makes it crappy
#				remainingVector = endPoint-(startPoint+raycast)
#			else:
#				#reached end of raycast distance with nothing found
#				print('Block not Found')
#				print('precise loops = '+str(preciseLoops))
#				print('NON-precise loops = '+str(clumsyLoops))
#				return [null, null]
#
#		raycastPreviousAxis = raycast #1 axis check before collision
#
#		indexAxis += 1
