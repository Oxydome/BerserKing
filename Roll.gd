extends Node2D

@onready var timer = $RollTimer

func StartRoll(dur: float) -> void:
	if timer == null:
		timer = get_node_or_null("RollTimer")
	if timer != null and timer.is_inside_tree():
		timer.start(dur)

func IsRolling() -> bool:
	if timer == null:
		timer = get_node_or_null("RollTimer")
	return timer != null and !timer.is_stopped()
