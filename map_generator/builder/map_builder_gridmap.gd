class_name MapBuilderGridMap
extends BaseMapBuilder

var grid_map: GridMap


func _create_grid_map(visual_settings: MapVisualSettings) -> void:
	if grid_map != null:
		return

	grid_map = GridMap.new()
	grid_map.name = "GridMap"
	grid_map.cell_size = Vector3(1, 1, 1)

	add_child(grid_map)

	if owner:
		grid_map.owner = owner

	print("GridMap created")

func build(map: Array, visual_settings: MapVisualSettings) -> void:
	clear()
	_create_grid_map(visual_settings)
	grid_map.mesh_library = _build_mesh_library(visual_settings)
	grid_map.bake_navigation = true
	
	print(grid_map)

	for x in range(map.size()):
		for y in range(map[x].size()):
			for z in range(map[x][y].size()):
				var tile_id = map[x][y][z]
				
				if tile_id == MapGenerator.EMPTY:
					continue
				
				if x == 10 and z == 10:
					print("Y=", y, " VALUE=", tile_id)
					
				grid_map.set_cell_item(Vector3i(x,y,z), tile_id)


func clear() -> void:
	if grid_map:
		grid_map.clear()


func setup_owner(scene_root: Node) -> void:

	owner = scene_root

	if grid_map:
		grid_map.owner = scene_root

func _build_mesh_library(visual_settings: MapVisualSettings) -> MeshLibrary:
	var lib := MeshLibrary.new()

	# FLOOR
	var transform := Transform3D.IDENTITY
	transform = transform.scaled(Vector3(.5, .5, .5))
	
	lib.create_item(MapGenerator.FLOOR)
	lib.set_item_mesh(MapGenerator.FLOOR, visual_settings.floor_mesh)
	lib.set_item_mesh_transform(MapGenerator.FLOOR, transform)

	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(1, 1, 1)

	lib.set_item_shapes(MapGenerator.FLOOR, [{
		"shape": floor_shape,
		"transform": Transform3D.IDENTITY
	}])

	# WALL
	transform = Transform3D.IDENTITY
	transform = transform.scaled(Vector3(.5, .5, .5))
	lib.create_item(MapGenerator.WALL)
	lib.set_item_mesh(MapGenerator.WALL, visual_settings.wall_mesh)
	lib.set_item_mesh_transform(MapGenerator.WALL, transform)

	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(1, 1, 1)

	lib.set_item_shapes(MapGenerator.WALL, [{
		"shape": wall_shape,
		"transform": Transform3D.IDENTITY
	}])
	
	print("WALL AQUI ", lib.get_item_list())
	
	return lib
