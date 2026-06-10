@tool
extends EditorPlugin

var dock: EditorDock


func _enter_tree() -> void:
	var dock_scene := preload("res://addons/map_generator/dock/dock.tscn").instantiate()
	
	dock = EditorDock.new()
	dock.add_child(dock_scene)
	
	set_dock()
	add_dock(dock)

func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()


func set_dock() -> void:
	dock.title = "Map Generator"
	dock.default_slot = EditorDock.DOCK_SLOT_LEFT_UL
	dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING
