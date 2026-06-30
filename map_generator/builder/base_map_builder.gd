@tool
class_name BaseMapBuilder
extends Node3D

@export var cell_size: float = 1.0

func build(_map: Array, visual_settings: MapVisualSettings) -> void:
	pass


func clear() -> void:
	pass
