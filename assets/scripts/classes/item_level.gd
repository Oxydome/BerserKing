class_name ItemLevel
extends Node

## Tracks item upgrade levels for an entity (Player).
## Corresponds to Unity ItemManager.ItemLevel.

@export var item_levels : Dictionary = {} # int (item_id) -> int (level_index)

var ItemLevels : Dictionary:
	get: return item_levels
	set(val): item_levels = val

func get_level(item_id: int) -> int:
	return item_levels.get(item_id, 0)

func set_level(item_id: int, lvl: int) -> void:
	item_levels[item_id] = lvl

func increment_level(item_id: int) -> int:
	var next_level = get_level(item_id) + 1
	item_levels[item_id] = next_level
	return next_level
