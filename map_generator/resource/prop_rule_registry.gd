class_name PropRuleRegistry
extends RefCounted

static func get_rules() -> Array[PropRule]:
	return [
		preload("res://addons/map_generator/resource/rock.tres"),
		preload("res://addons/map_generator/resource/rock1.tres"),
		preload("res://addons/map_generator/resource/pano1.tres"),
	]
