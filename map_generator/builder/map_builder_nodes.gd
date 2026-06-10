@tool
class_name MapBuilderNodes
extends BaseMapBuilder


func build(map: Array, visual_settings: MapVisualSettings) -> void:
	clear()

	for x in range(map.size()):
		for y in range(map[x].size()):
			for z in range(map[x][y].size()):

				if map[x][y][z] == MapGenerator.FLOOR:
					if y != 0:
						continue

				_spawn_block(Vector3(x, y, z))


func _spawn_block(pos: Vector3) -> void:

	var cell := MapCell.new()
	cell.grid_position = Vector3i(pos)

	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()

	cell.add_child(mesh)

	cell.position = pos * cell_size

	add_child(cell)

	var scene_root := get_tree().edited_scene_root

	cell.owner = scene_root
	mesh.owner = scene_root

	cell.name = str(pos)


func clear() -> void:

	for child in get_children():
		child.queue_free()
