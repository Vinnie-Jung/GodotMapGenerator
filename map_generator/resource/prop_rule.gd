class_name PropRule
extends Resource

enum Type {
	OBSTACLE,
	INTERACTIVE,
	WALL_ATTACHED,
	RANDOM
}

enum Anchor {
	FLOOR,
	WALL,
	CEILING,
	FREE
}

enum Tile {
	EMPTY,
	FLOOR,
	WALL,
	CEILING
}


@export var scene: PackedScene
@export var weight: float = 1.0

@export var type: Type = Type.OBSTACLE
@export var target_tile: Tile = Tile.EMPTY

@export var anchor: Anchor = Anchor.FLOOR
@export var height_offset: int = 0

# footprint (ocupa espaço)
@export var size: Vector3i = Vector3i(1, 1, 1)

# condições
@export var requires_empty_space: bool = true
@export var must_be_on_floor: bool = true
