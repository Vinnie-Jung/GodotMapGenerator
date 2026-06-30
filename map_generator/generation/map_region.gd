@tool
class_name MapRegion
extends RefCounted

## Connected floor region found during flood fill.

var cells : Array[Vector3i] = []

func get_size() -> int:
	return cells.size()

func get_center() -> Vector3:
	var center := Vector3.ZERO

	for cell in cells:
		center += Vector3(cell)

	return center / max(1, cells.size())
