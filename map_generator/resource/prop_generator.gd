class_name PropGenerator
extends RefCounted

var rng := RandomNumberGenerator.new()
var _parent: Node3D
var _spawned_props: Array[Node] = []
var _settings: MapGenerationSettings
var builder: BaseMapBuilder

func generate(map: Array, settings: MapGenerationSettings, rules: Array[PropRule], parent: Node3D) -> void:
	if not settings.seed.is_empty():
		rng.seed = settings.seed.hash()
	else:
		rng.randomize()
		
	#await clear()
	_parent = parent
	_settings = settings
	print("PARENT READY:", parent.is_inside_tree())
	print("TREE:", parent.get_tree())
	
	for i in parent.get_children():
		if i is BaseMapBuilder:
			builder = i
			break
		if i is NavigationRegion3D:
			builder = i.get_node("Map")
			break
	
	for rule in rules:
		_process_rule(map, rule, parent)
	


func _process_rule(map: Array, rule: PropRule, parent: Node3D) -> void:
	match rule.type:
		PropRule.Type.OBSTACLE:
			_process_obstacle(map, rule, parent)

		PropRule.Type.INTERACTIVE:
			pass#_process_interactive(map, rule, parent)

		PropRule.Type.WALL_ATTACHED:
			_process_wall_attached(map, rule, parent)

		PropRule.Type.RANDOM:
			pass#_process_random(map, rule, parent)


func _collect_candidates(map: Array, rule: PropRule) -> Array:
	var result := []

	for x in range(map.size()):
		for y in range(map[x].size()):
			for z in range(map[x][y].size()):

				var pos := Vector3i(x, y, z)

				if map[x][y][z] == rule.target_tile:
					result.append(pos)

	return result


func _check_rule(map: Array, rule: PropRule, pos: Vector3i) -> bool:
	for req in rule.required_checks:
		if not _eval_condition(map, pos, req):
			return false

	for forbid in rule.forbidden_checks:
		if _eval_condition(map, pos, forbid):
			return false

	return true


func _eval_condition(map: Array, pos: Vector3i, cond) -> bool:
	var target = pos + cond.offset

	if not _in_bounds(map, target):
		return false

	return map[target.x][target.y][target.z] == cond.tile


func _spawn(rule: PropRule, pos: Vector3i, parent: Node3D) -> void:
	var instance := rule.scene.instantiate()
	
	var props_root := builder.get_node_or_null("PropsRoot")

	if props_root == null:
		props_root = Node3D.new()
		props_root.name = "PropsRoot"
		props_root.set_meta("propsroot", true)
		builder.add_child(props_root)
		props_root.owner = parent

	props_root.add_child(instance)
	instance.position = _get_spawn_position(pos, rule)
	instance.owner = parent
	_spawned_props.append(instance)


func _get_spawn_position(pos: Vector3i, rule: PropRule) -> Vector3:
	var final := Vector3(pos)
	match rule.anchor:
		PropRule.Anchor.FLOOR:
			final.y = pos.y + rule.height_offset

		PropRule.Anchor.WALL:
			final.y = pos.y + rule.height_offset

		PropRule.Anchor.CEILING:
			final.y = pos.y + rule.height_offset

		PropRule.Anchor.FREE:
			final = Vector3(pos)

	return final + Vector3(0.5, 0.5, 0.5)

func _in_bounds(map: Array, pos: Vector3i) -> bool:
	return (
		pos.x >= 0 and pos.x < map.size() and
		pos.y >= 0 and pos.y < map[pos.x].size() and
		pos.z >= 0 and pos.z < map[pos.x][pos.y].size()
	)

func _process_obstacle(map: Array, rule: PropRule, parent: Node3D) -> void:
	var density := _settings.prop_density / 100.0
	var max_props := int(_settings.floor_count * density)
	var placed := 0
	print("DENSITY ", density)
	
	for x in range(map.size()):
		for y in range(map[x].size()):
			for z in range(map[x][y].size()):
				if placed >= max_props:
					break
					
				var pos := Vector3i(x, y, z)

				if not _check_base_conditions(map, rule, pos):
					continue

				if not _check_footprint(map, rule, pos):
					continue
				
				if rng.randf() > density:
					continue
				
				if rng.randf() > rule.weight:
					continue

				print("trying spawn rock at:", pos)
				_spawn(rule, pos, parent)
				placed += 1

func _check_base_conditions(map: Array, rule: PropRule, pos: Vector3i) -> bool:

	if not _in_bounds(map, pos):
		return false

	if rule.must_be_on_floor:
		if map[pos.x][pos.y][pos.z] != MapGenerator.FLOOR:
			return false

	return true

func _check_footprint(map: Array, rule: PropRule, pos: Vector3i) -> bool:

	for x in range(rule.size.x):
		for y in range(rule.size.y):
			for z in range(rule.size.z):

				var p := pos + Vector3i(x, y, z)

				if not _in_bounds(map, p):
					return false

				if rule.requires_empty_space:
					if map[p.x][p.y][p.z] != MapGenerator.FLOOR:
						return false

	return true


func _process_wall_attached(map, rule, parent):

	for x in range(map.size()):
		for y in range(map[x].size()):
			for z in range(map[x][y].size()):

				var pos := Vector3i(x,y,z)

				if map[pos.x][pos.y][pos.z] != MapGenerator.WALL:
					continue

				if not _has_floor_below(map, pos):
					continue

				if rng.randf() > rule.weight:
					continue

				_spawn(rule, pos, parent)


func _has_floor_below(map: Array, pos: Vector3i) -> bool:
	var below := Vector3i(pos.x, pos.y - 1, pos.z)

	if not _in_bounds(map, below):
		return false

	return map[below.x][below.y][below.z] == MapGenerator.FLOOR


func clear():
	for p in _spawned_props:
		if is_instance_valid(p):
			p.queue_free()

	_spawned_props.clear()
