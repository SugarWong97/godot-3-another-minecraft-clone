extends Node
onready var oWorldChunks = get_node(Nodelist.oWorldChunks)
onready var oWorldGen = get_node(Nodelist.oWorldGen)
onready var oPlayer = get_node(Nodelist.oPlayer)

var blockChecks = {}
var blockCheckerScene = preload("res://spawn/BlockCheck.tscn")
var basicDir = global.direction

func removeBlockConditions(worldPos):
	var chunkID = oWorldChunks.getChunk(worldPos)
	if chunkID:
		var localPos = worldPosToLocalPos(worldPos)
		if chunkID.blockMap[localPos.x][localPos.y][localPos.z]:
			chunkID.removeBlock(localPos)

func addBlockConditions(worldPos):
	var chunkID = oWorldChunks.getChunk(worldPos)
	if chunkID:
		var localPos = worldPosToLocalPos(worldPos)
		if not chunkID.blockMap[localPos.x][localPos.y][localPos.z]:
			chunkID.addBlock(localPos)

func worldBlock(worldPos):
	var chunkID = oWorldChunks.getChunk(worldPos)
	if chunkID:
		var pos = worldPosToLocalPos(worldPos)
		return chunkID.blockMap[pos.x][pos.y][pos.z]
	return oWorldGen.EMPTY #return empty when no chunk found

func worldPosToLocalPos(worldPos):
	var x = fposmod(worldPos.x,oWorldChunks.CHUNK_SIZE_X)
	var y = fposmod(worldPos.y,oWorldChunks.CHUNK_SIZE_Y)
	var z = fposmod(worldPos.z,oWorldChunks.CHUNK_SIZE_Z)
	var localPos = Vector3(x,y,z).abs()
	return localPos
	#return Vector3(fposmod(worldPos.x,oWorldChunks.CHUNK_SIZE_X),fposmod(worldPos.y,oWorldChunks.CHUNK_SIZE_Y),fposmod(worldPos.z,oWorldChunks.CHUNK_SIZE_Z)).abs() #rare error when using this line

func raycastBlockmap(startPoint, endPoint):
	var raycast = Vector3()
	var remainingVector = endPoint-startPoint
	var increment = remainingVector.normalized()
	
	var abcKeys = blockChecks.keys()
	for i in abcKeys.size():
		blockChecks[abcKeys[i]].markForCulling = true
	
	var raycastData = {}
	
	var previousCheck
	while true:
		var newCheck = (startPoint+raycast).floor()
		if previousCheck != newCheck:
			previousCheck = newCheck
			placeAreaCheck(newCheck)
		
		raycastData = oPlayer.get_world().get_direct_space_state().intersect_ray(startPoint, startPoint+raycast, [], 4, true, true) #This line is cheap, the performance cost comes from placing the areaChecks
		if raycastData:
			break
		
		raycast += increment
		if remainingVector.length() <= increment.length():
			break
		else:
			remainingVector -= increment
	
	for i in abcKeys.size():
		var id = blockChecks[abcKeys[i]]
		if id.markForCulling == true:
			blockChecks.erase(id.translation)
			id.queue_free()
	
	return raycastData

func placeAreaCheck(raypos):
	var superpos = raypos #check original position first
	for i in 7: # spawn blockcheck in directions AND on original position
		if worldBlock(superpos):
			
			if blockChecks.has(superpos) == false:

				var id = blockCheckerScene.instance()
				add_child(id)
				id.translation = superpos

				blockChecks[superpos] = id
			else:
				blockChecks[superpos].markForCulling = false
		superpos = raypos+basicDir[i-1] #1-6 becomes 0-5


# Old raycast code, had some small flaws so I ditched it for what I have now. Performance was similar.

# move a maximum of 1 distance
# do axis X, then do axis Y, then do axis Z
# then repeat.
# when we reach the remainder, only do the remainder
# returns either blockmap position when there's a collision, or returns null.

#func raycastBlockMap(startPoint, endPoint, returnPreviousPositionToo):
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
#		if preciseChecking == true:
#			preciseLoops += 1
#		else:
#			clumsyLoops += 1
#
#		if indexAxis == 3:
#			indexAxis = 0
#			redoRearraged += 1
#			if redoRearraged != 1 and preciseChecking == false:
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
#		if oWorldInteract.worldBlock((startPoint+raycast).floor()):
#			if preciseChecking == false:
#				preciseChecking = true
#
#				increment = preciseIncrement
#				remainingVector = raycast-raycastPreviousVector #precise checks needs to be limited here, there's an edge case where the non-precise-found-block is not found by the precise check.
#				raycast = raycastPreviousVector #rewind position
#
#			else:
#				return [startPoint+raycast, startPoint+raycastPreviousAxis] #Returns two values, a collision point and a pointBeforeCollision. Or returns [null,null] if no collision is found.
#
#		#remaining
#		if remainingVector == Vector3(0,0,0):
#			if preciseChecking == true and preciseCheckMissesTheImpreciseBlock == false:
#				preciseCheckMissesTheImpreciseBlock = true
#				increment = clumsyIncrement #for the sake of optimization, but doing this makes it a bit crappy
#				remainingVector = endPoint-(startPoint+raycast)
#			else:
#				#reached end of raycast distance with nothing found
#				return [null, null]
#
#		raycastPreviousAxis = raycast #1 axis check before collision
#
#		indexAxis += 1
