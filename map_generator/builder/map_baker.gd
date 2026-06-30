@tool
extends NavigationRegion3D

@onready var map_builder: BaseMapBuilder = $MapBuilder
@onready var nav_region: NavigationRegion3D = $NavigationRegion3D


func generate_and_bake(map: Array) -> void:
	await get_tree().process_frame
	nav_region.bake_navigation_mesh()
