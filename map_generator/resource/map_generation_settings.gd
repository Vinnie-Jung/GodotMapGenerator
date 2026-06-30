class_name MapGenerationSettings
extends Resource

@export_category("Map Settings")
@export var map_size_x : int = 20
@export var map_size_y : int = 5
@export var map_size_z : int = 20

@export var generate_ceilings : bool = true
@export var generate_closed_map : bool = true

@export_category("Props Settings")
@export var generate_props : bool = true
@export_range(0, 100)
var prop_density: int = 35

@export_category("Navigation Settings")
@export var generate_navigation : bool = true

@export_category("Seed Settings")
@export var seed : String = ""

var floor_count: int = 0
var wall_count: int = 0
var empty_count: int = 0
