tool
extends EditorPlugin

const nameOfNode = 'Game' # Upon selecting this node in editor, the script attatched to it will be overwritten.
var prefix = 'o'

var sceneNodes
var file = File.new()
var canGenerate = true
var editorSelection = get_editor_interface().get_selection()
func _ready():
	editorSelection.connect("selection_changed", self, "_on_selection_changed")

func _on_selection_changed():
	var selectedNodes = editorSelection.get_selected_nodes()
	if selectedNodes.empty() == false:
		if selectedNodes[0].name == nameOfNode:
			print("Updated Nodelist. Close and reopen its script to see changes.")
			var writeToPath = selectedNodes[0].get_script().get_path()
			generateList(writeToPath)

func generateList(path):
	file.open(path, File.WRITE)
	file.store_line("#This file was automatically created by an EditorPlugin. Don't edit it, it will be overwritten.")
	file.store_line("extends Node")
	file.store_line("class_name Nodelist")
	file.store_line("")
	sceneNodes = get_tree().get_edited_scene_root().get_parent()
	getAllNodes(sceneNodes)
	file.close()

func getAllNodes(node):
	for N in node.get_children():
		file.store_line('const '+prefix+N.get_name()+' = '+'"/root/'+sceneNodes.get_path_to(N)+'"')
		if N.get_child_count() > 0:
			getAllNodes(N)
