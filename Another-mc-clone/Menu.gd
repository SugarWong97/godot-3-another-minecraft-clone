extends Control
var autostart = false

func _ready():
	$OptionFOV.text = str(settings.FoV)
	$OptionMouseSensitivity.text = str(settings.mouseSensitivity)
	$OptionViewDistance.text = str(settings.VIEW_DISTANCE)
	$OptionChunkSizeX.text = str(settings.CHUNK_SIZE_X)
	$OptionChunkSizeY.text = str(settings.CHUNK_SIZE_Y)
	$OptionChunkSizeZ.text = str(settings.CHUNK_SIZE_Z)
	$OptionCaveGen.pressed = settings.cavesOn
	$OptionOccludeCaveLight.pressed = settings.occludeCaveLight
	$OptionFadeDistanceBlue.pressed = settings.fadeDistanceBlue
	$OptionEnableLighting.pressed = settings.enableLighting
	
	if autostart == true:
		_on_MenuButton_pressed()

func _on_OptionFOV_text_changed(new_text):
	settings.FoV = int(new_text)
func _on_OptionMouseSensitivity_text_changed(new_text):
	settings.mouseSensitivity = float(new_text)
func _on_OptionViewDistance_text_changed(new_text):
	settings.VIEW_DISTANCE = int(new_text)
func _on_OptionChunkSizeX_text_changed(new_text):
	settings.CHUNK_SIZE_X = int(new_text)
func _on_OptionChunkSizeY_text_changed(new_text):
	settings.CHUNK_SIZE_Y = int(new_text)
func _on_OptionChunkSizeZ_text_changed(new_text):
	settings.CHUNK_SIZE_Z = int(new_text)
func _on_OptionCaveGen_pressed():
	settings.cavesOn = !settings.cavesOn
func _on_OptionOccludeCaveLight_pressed():
	settings.occludeCaveLight = !settings.occludeCaveLight
func _on_OptionFadeDistanceBlue_pressed():
	settings.fadeDistanceBlue = !settings.fadeDistanceBlue
func _on_OptionEnableLighting_pressed():
	settings.enableLighting = !settings.enableLighting
func _on_MenuButton_pressed():
	get_tree().change_scene('res://Game.tscn')
