# Opening a script will switch to distraction free mode, moving mouse to left side of screen will close distraction free mode.
tool
extends EditorPlugin
var editor_interface = get_editor_interface()
var script_editor = editor_interface.get_script_editor()
var ui = editor_interface.get_base_control()

func _ready():
	script_editor.connect("editor_script_changed", self, "onScriptChanged")

func onScriptChanged(inScript):
	editor_interface.set_distraction_free_mode(true)

func _process(delta):
	var mouseCoordinates = ui.get_local_mouse_position()
	if mouseCoordinates.x < 30:
		editor_interface.set_distraction_free_mode(false)
