extends Camera
# Camera has exact same position has Player. The CollisionBox is what determines eye height for the camera distance from the ground.
onready var oWorldGen = get_node(Nodelist.oWorldGen)
onready var oPlayerLight = get_node(Nodelist.oPlayerLight)
onready var oSunAngle = get_node(Nodelist.oSunAngle)
onready var oSelectorLight = get_node(Nodelist.oSelectorLight)

onready var TERRAIN_MAT = oWorldGen.TERRAIN_MAT

var VIEW_DISTANCE = settings.VIEW_DISTANCE
const fadeThickness = 5
var chunkSpaceDistance
var fadeDistanceBlue
var fogDistance = 0.00



func _ready():
	chunkSpaceDistance = max(settings.CHUNK_SIZE_X,settings.CHUNK_SIZE_Z)
	fov = settings.FoV
	if settings.fadeDistanceBlue == false:
		set_physics_process(false)
		TERRAIN_MAT.set_shader_param('distance_fade_min', 0)
		TERRAIN_MAT.set_shader_param('distance_fade_max', 1000000000000)
	
	if settings.enableLighting == false:
		environment.ambient_light_color = Color(1,1,1,1)
		environment.ambient_light_sky_contribution = 0
		oPlayerLight.visible = false
		oSunAngle.visible = false
		oSelectorLight.visible = false

func _physics_process(delta):
	var fogDistanceDesired = (VIEW_DISTANCE*chunkSpaceDistance) - (chunkSpaceDistance*0.5) - fadeThickness
	fogDistance = lerp(fogDistance, fogDistanceDesired, 0.003)
	TERRAIN_MAT.set_shader_param('distance_fade_min', fogDistance-fadeThickness)
	TERRAIN_MAT.set_shader_param('distance_fade_max', fogDistance)
