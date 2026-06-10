@tool
class_name MapGenerator
extends RefCounted

## Generates cave-like maps using a procedural generation pipeline.
##
## Current pipeline:
## 1. Random Fill
## 2. Cellular Automata
## 3. Region Detection
## 4. Region Cleanup
## 5. Region Connection
##
## The resulting map is stored as a 3D array where:
## - 0 = Floor
## - 1 = Wall
##
## The generator is designed to work primarily on the XZ plane,
## while still supporting multiple Y levels.

const EMPTY: int = -1
const FLOOR: int = 0
const WALL: int = 1

var floor_count: int
var wall_count: int
var empty_count: int

var _settings : MapGenerationSettings
var _map : Array = []
var _regions : Array[MapRegion] = []

func generate(settings: MapGenerationSettings) -> Array:
	"""
	Executes the complete map generation pipeline.

	:param settings:
		Generation settings provided by the user.

	:return:
		A 3D array containing the generated map.
	"""

	_settings = settings

	_initialize_map()
	_random_fill()
	_apply_cellular_automata()
	_detect_regions()
	_remove_small_regions()
	_connect_regions()

	return _map


# ============================================================================
# INITIALIZATION
# ============================================================================

## Creates an empty map structure.
func _initialize_map() -> void:
	floor_count = 0
	empty_count = 0
	wall_count = 0
	
	_map.clear()

	for x in range(_settings.map_size_x):

		var column := []

		for y in range(_settings.map_size_y):

			var layer := []

			for z in range(_settings.map_size_z):
				layer.append(WALL)

			column.append(layer)

		_map.append(column)
	debug_print()


# ============================================================================
# RANDOM FILL
# ============================================================================

## Generates the initial random distribution of walls and floors.
##
## This version adds a subtle center bias to improve density
## distribution in larger maps (prevents empty middle areas).
func _random_fill() -> void:

	var rng := RandomNumberGenerator.new()

	if not _settings.seed.is_empty():
		rng.seed = _settings.seed.hash()
	else:
		rng.randomize()

	var base_wall_chance : float = clamp(
	40.0 + ((_settings.map_size_x + _settings.map_size_z) * 0.1),
	40.0,
	55.0
)
	print(40.0 + ((_settings.map_size_x + _settings.map_size_z) * 0.05))

	var center := Vector2(
		_settings.map_size_x * 0.5,
		_settings.map_size_z * 0.5
	)

	for x in range(_settings.map_size_x):

		for z in range(_settings.map_size_z):

			# ------------------------------------------------------------
			# Border check (always solid walls)
			# ------------------------------------------------------------
			var is_border: bool = (
				x == 0
				or x == _settings.map_size_x - 1
				or z == 0
				or z == _settings.map_size_z - 1
			)

			var cell_type := FLOOR
			var closed_map: bool = _settings.generate_closed_map
			
			if is_border:
				if closed_map:
					cell_type = WALL
				else:
					var wall_chance: int = rng.randi_range(0, 100)
					if wall_chance > base_wall_chance:
						cell_type = FLOOR
					else:
						cell_type = WALL
					

			else:
				# ------------------------------------------------------------
				# Center bias (fixes sparse middle regions in large maps)
				# ------------------------------------------------------------
				var pos := Vector2(x, z)

				var dist_to_center := pos.distance_to(center)
				var max_dist := center.length()

				var center_factor := 1.0 - (dist_to_center / max_dist)

				var wall_chance := base_wall_chance + (center_factor * 10.0)

				if rng.randf() * 100.0 < wall_chance:
					cell_type = WALL
				else:
					cell_type = FLOOR

			# ------------------------------------------------------------
			# Fill entire column (XZ-driven generation)
			# ------------------------------------------------------------
			if cell_type == FLOOR:

				_set_cell(x, 0, z, FLOOR)

				for y in range(1, _settings.map_size_y):
					_set_cell(x, y, z, EMPTY)

			else:

				for y in range(_settings.map_size_y):
					_set_cell(x, y, z, WALL)
	debug_print()

# ============================================================================
# CELLULAR AUTOMATA
# ============================================================================

## Applies multiple cellular automata iterations in order
## to smooth the cave structure.
func _apply_cellular_automata() -> void:
	var iterations = clamp(int(min(_settings.map_size_x, _settings.map_size_z) / 10), 3, 8)

	for i in range(iterations):
		_run_cellular_automata_iteration()
		print(i)
		debug_print()


## Executes a single cellular automata iteration.
func _run_cellular_automata_iteration() -> void:
	var new_map := []

	# Duplicate current map
	for x in range(_settings.map_size_x):
		var column := []
		for y in range(_settings.map_size_y):
			var layer := []
			for z in range(_settings.map_size_z):
				layer.append(_get_cell(x, y, z))

			column.append(layer)
		new_map.append(column)

	for x in range(_settings.map_size_x):
		for z in range(_settings.map_size_z):
			var wall_neighbors := _count_wall_neighbors(x, z)
			var new_value := FLOOR

			if wall_neighbors >= 5:
				new_value = WALL

			if new_value == FLOOR:
				new_map[x][0][z] = FLOOR

				for y in range(1, _settings.map_size_y):
					new_map[x][y][z] = EMPTY

			else:
				for y in range(_settings.map_size_y):
					new_map[x][y][z] = WALL

	_map = new_map

## Counts neighboring wall cells around the given XZ position.
##
## Out-of-bounds positions are considered walls.
func _count_wall_neighbors(x: int, z: int) -> int:
	var count := 0
	for offset_x in range(-1, 2):
		for offset_z in range(-1, 2):
			if offset_x == 0 and offset_z == 0:
				continue

			var neighbor_x := x + offset_x
			var neighbor_z := z + offset_z

			var outside_map := (
				neighbor_x < 0
				or neighbor_x >= _settings.map_size_x
				or neighbor_z < 0
				or neighbor_z >= _settings.map_size_z
			)

			if outside_map:
				count += 1
				continue

			if _get_cell(neighbor_x, 0, neighbor_z) == WALL:
				count += 1

	return count


# ============================================================================
# REGION DETECTION
# ============================================================================

## Detects connected floor regions using flood fill.
##
## Returns groups of connected floor cells.
func _detect_regions() -> void:
	_regions.clear()
	var visited := {}

	for x in range(_settings.map_size_x):
		for z in range(_settings.map_size_z):
			var position := Vector3i(x, 0, z)

			if visited.has(position):
				continue

			if _get_cell(x, 0, z) == WALL:
				continue

			var region := _flood_fill(position, visited)

			if region.get_size() > 0:
				_regions.append(region)


## Executes a flood fill starting from a floor cell.
func _flood_fill(start_position: Vector3i, visited: Dictionary) -> MapRegion:
	var region := MapRegion.new()
	var queue : Array[Vector3i] = []

	queue.append(start_position)
	visited[start_position] = true

	while not queue.is_empty():
		var current : Vector3i = queue.pop_front()
		region.cells.append(current)

		var neighbors := [
			Vector3i(current.x + 1, 0, current.z),
			Vector3i(current.x - 1, 0, current.z),
			Vector3i(current.x, 0, current.z + 1),
			Vector3i(current.x, 0, current.z - 1)
		]

		for neighbor in neighbors:
			if not _is_valid_position(neighbor.x, 0, neighbor.z):
				continue

			if visited.has(neighbor):
				continue

			if _get_cell(neighbor.x, 0, neighbor.z) == WALL:
				continue

			visited[neighbor] = true
			queue.append(neighbor)

	return region


# ============================================================================
# REGION CLEANUP
# ============================================================================

## Removes regions considered too small.
##
## Small disconnected floor regions are converted into walls.
func _remove_small_regions() -> void:
	var minimum_region_size := _get_min_region_size()
	
	for region in _regions:
		if region.get_size() >= minimum_region_size:
			continue

		for cell in region.cells:
			_set_cell(cell.x, cell.y, cell.z, WALL)
	
	_detect_regions()


## Calculates the minimum valid region size.
func _get_min_region_size() -> int:
	return max(5, int((_settings.map_size_x * _settings.map_size_z) * 0.01))


# ============================================================================
# REGION CONNECTION
# ============================================================================

## Connects large disconnected regions together.
##
## The current implementation can use:
## - Nearest region strategy
## - Minimum spanning tree (future implementation)
func _connect_regions() -> void:
	if _regions.size() <= 1:
		return

	_regions.sort_custom(
		func(a: MapRegion, b: MapRegion):
			return a.get_size() > b.get_size()
	)

	var main_region := _regions[0]

	for i in range(1, _regions.size()):
		var target_region := _regions[i]
		_detect_regions()
		var connection := _find_closest_connection(main_region, target_region)

		_create_corridor(connection.start, connection.end)
	#_detect_regions()
	debug_print()


func _find_closest_connection(
	region_a: MapRegion,
	region_b: MapRegion
) -> RegionConnection:

	var result := RegionConnection.new()

	result.distance = INF

	for cell_a in region_a.cells:

		for cell_b in region_b.cells:

			var distance := (
				Vector2(cell_a.x, cell_a.z)
				.distance_to(
					Vector2(cell_b.x, cell_b.z)
				)
			)

			if distance < result.distance:

				result.distance = distance
				result.start = cell_a
				result.end = cell_b

	return result

## Creates a corridor between two points.
func _create_corridor(
	start_position: Vector3i,
	end_position: Vector3i
) -> void:
	pass


# ============================================================================
# UTILITIES
# ============================================================================

## Returns true if the given position is inside map bounds.
func _is_valid_position(
	x: int,
	y: int,
	z: int
) -> bool:

	return (
		x >= 0
		and x < _settings.map_size_x
		and y >= 0
		and y < _settings.map_size_y
		and z >= 0
		and z < _settings.map_size_z
	)


## Sets a cell value.
func _set_cell(
	x: int,
	y: int,
	z: int,
	value: int
) -> void:

	_map[x][y][z] = value


## Gets a cell value.
func _get_cell(
	x: int,
	y: int,
	z: int
) -> int:

	return _map[x][y][z]


func debug_print() -> void:
	floor_count = 0
	wall_count = 0
	empty_count = 0
	
	print("")
	print("=== MAP DEBUG ===")

	for z in range(_settings.map_size_z):

		var row := ""

		for x in range(_settings.map_size_x):

			if _get_cell(x, 0, z) == WALL:
				row += "#"
				wall_count += 1
				
			else:
				row += "."
				floor_count += 1

		print(row)
