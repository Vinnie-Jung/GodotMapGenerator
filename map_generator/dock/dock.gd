@tool
extends VBoxContainer

signal map_generated(map: Array)

const MAP_VISUAL_SETTINGS = preload("res://addons/map_generator/resource/map_visual_settings.tres")


enum BuildMode
{
	NODES,
	GRIDMAP
}

@export var build_mode: BuildMode = BuildMode.GRIDMAP
@onready var x_spin: SpinBox = %XSpin
@onready var y_spin: SpinBox = %YSpin
@onready var z_spin: SpinBox = %ZSpin
@onready var closed_map_check: CheckBox = %ClosedMapCheck
@onready var ceiling_check: CheckBox = %CeilingCheck
@onready var generate_props_check: CheckBox = %GeneratePropsCheck
@onready var rarity_slider: HSlider = %RaritySlider
@onready var rarity_value: Label = %RarityValue
@onready var generate_navigation_check: CheckBox = %GenerateNavigationCheck
@onready var seed_input: LineEdit = %SeedInput
@onready var generate_button: Button = %GenerateButton

var current_map: Array
var current_settings: MapGenerationSettings
var current_navigation: NavigationRegion3D
var current_map_builder: BaseMapBuilder

func _ready() -> void:
	randomize()
	_setup_ui()
	_connect_signals()


func _setup_ui() -> void:
	_set_main_scroll()
	_update_props_visibility()
	_set_random_seed()
	_set_rarity_value(rarity_slider.value)


func _connect_signals() -> void:
	%RandomSeedButton.pressed.connect(_set_random_seed)
	rarity_slider.value_changed.connect(_set_rarity_value)
	%GeneratePropsCheck.toggled.connect(_update_props_visibility)
	generate_button.pressed.connect(start_generation)
	map_generated.connect(start_build)


func _set_main_scroll() -> void:
	var main_scroll: ScrollContainer = %MainScroll
	
	main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	main_scroll.clip_contents = true


func _set_rarity_value(value: float) -> void:
	rarity_value.text = "%d%%" % int(value)


func _set_random_seed() -> void:
	seed_input.text = str(randi_range(100000, 999999))


func _update_props_visibility(_toggled: bool = false) -> void:
	%RarityContainer.visible = generate_props_check.button_pressed
	%PropsInfoLabel.visible = generate_props_check.button_pressed


func _collect_settings() -> MapGenerationSettings:
	var data: MapGenerationSettings = MapGenerationSettings.new()
	
	# Map Settings
	data.map_size_x = int(x_spin.value)
	data.map_size_y = int(y_spin.value)
	data.map_size_z = int(z_spin.value)
	data.generate_closed_map = closed_map_check.button_pressed
	data.generate_ceilings = ceiling_check.button_pressed
	
	# Props Settings
	data.generate_props = generate_props_check.button_pressed
	data.prop_density = int(rarity_slider.value)
	
	# Navigation
	data.generate_navigation = generate_navigation_check.button_pressed
	
	# Seed
	data.seed = seed_input.text
	
	return data


func start_generation() -> void:
	var map: MapGenerator = MapGenerator.new()
	var generated_map: Array = map.generate(_collect_settings())
	
	current_map = generated_map
	current_settings = _collect_settings()
	
	current_settings.floor_count = map.floor_count
	current_settings.wall_count = map.wall_count
	current_settings.empty_count = map.empty_count
	
	if generated_map:
		map_generated.emit(generated_map)


func start_build(map: Array) -> void:

	var editor_scene = get_tree().edited_scene_root
	var map_builder: BaseMapBuilder = null
	editor_scene.get_tree_string_pretty()

	var desired_type = _get_builder_type()

	for c in editor_scene.get_children():
		if c is NavigationRegion3D:
			c.queue_free()
		# TODO: Implement regenerate/generate another
		if c is BaseMapBuilder:
			map_builder = c

	if map_builder == null:

		map_builder = _create_builder()
		map_builder.name = "Map"

		editor_scene.add_child(map_builder)
		if desired_type is MapBuilderGridMap:
			map_builder.setup_owner(editor_scene)
		else:
			map_builder.owner = editor_scene
	
	current_map_builder = map_builder
	await map_builder.clear()
	await map_builder.call_deferred("build", map, MAP_VISUAL_SETTINGS)

	await get_tree().process_frame
	
	if current_settings.generate_props:
		start_prop_placement(map_builder)
	
	if current_settings.generate_navigation:
		start_bake(map_builder)

func start_bake(builder: BaseMapBuilder) -> void:
	var editor_scene = get_tree().edited_scene_root
	var nav_region := editor_scene.find_child("NavRegion")

	await get_tree().process_frame
	
	if not nav_region:
		nav_region = NavigationRegion3D.new()
		nav_region.navigation_mesh = NavigationMesh.new()
		nav_region.name = "NavRegion"
		
		editor_scene.add_child(nav_region)
		nav_region.owner = editor_scene
		
		# MESH
		var nav_mesh := NavigationMesh.new()
		nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
		nav_mesh.geometry_collision_mask = 1
		nav_mesh.agent_radius = 0.25
		nav_mesh.cell_size = 0.25
		nav_mesh.agent_max_climb = 0.0
		
		nav_region.navigation_mesh = nav_mesh
		current_navigation = nav_region
		
		builder.reparent(nav_region)
	
	await get_tree().process_frame
	if nav_region:
		nav_region.bake_navigation_mesh()


func _create_builder():
	match build_mode:
		BuildMode.NODES:
			return MapBuilderNodes.new()
			
		BuildMode.GRIDMAP:
			return MapBuilderGridMap.new()

	return null


func _get_builder_type():
	match build_mode:
		BuildMode.NODES:
			return MapBuilderNodes

		BuildMode.GRIDMAP:
			return MapBuilderGridMap

	return null


func start_prop_placement(map_builder: BaseMapBuilder) -> void:
	var editor_scene = get_tree().edited_scene_root
	var prop_generator: PropGenerator = PropGenerator.new()
	await prop_generator.clear()

	var rules := PropRuleRegistry.get_rules() # ou array direto depois

	prop_generator.generate(
		current_map,
		current_settings,
		rules,
		editor_scene
	)
	
	for c in editor_scene.get_children():
		if c.has_meta("propsroot"):
			c.reparent(current_map_builder)
			break
		
