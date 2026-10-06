class_name Door
extends Area2D

## Interactive Door Trigger for transitions between lobby, levels, and dungeon.

@export var target_scene : String = "res://scenes/game.tscn"
@export var prompt_text : String = "Enter Dungeon [E]"
@export var auto_enter_on_walk : bool = true

var player_inside : bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if has_node("Label"):
		$Label.text = prompt_text
		$Label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player" or "health" in body:
		player_inside = true
		if has_node("Label"):
			$Label.visible = true
		if auto_enter_on_walk:
			call_deferred("_enter_door")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player" or "health" in body:
		player_inside = false
		if has_node("Label"):
			$Label.visible = false

func _input(event: InputEvent) -> void:
	if player_inside and (event.is_action_pressed("ui_accept") or event.is_action_pressed("dash") or (event is InputEventKey and event.pressed and event.keycode == KEY_E)):
		_enter_door()

func _enter_door() -> void:
	if target_scene != "":
		var global = get_node_or_null("/root/Global")
		if global != null and global.has_method("change_scene"):
			global.change_scene("res://assets/scripts/globals/default_transition.tscn", target_scene, "fade_center")
		else:
			get_tree().change_scene_to_file(target_scene)
