extends Control

@export var play_button: Button
@export var level_select_button: Button
@export var character_select_button: Button
@export var options_button: Button
@export var exit_button: Button

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	# Wire up buttons if assigned via inspector or find them by pattern
	if play_button == null:
		play_button = find_child("*Play*", true, false) as Button
	if level_select_button == null:
		level_select_button = find_child("*LevelSelect*", true, false) as Button
	if character_select_button == null:
		character_select_button = find_child("*CharacterSelect*", true, false) as Button
	if options_button == null:
		options_button = find_child("*Options*", true, false) as Button
	if exit_button == null:
		exit_button = find_child("*Quit*", true, false) as Button
		if exit_button == null:
			exit_button = find_child("*Exit*", true, false) as Button

	if play_button != null and not play_button.pressed.is_connected(_on_play_button_pressed):
		play_button.pressed.connect(_on_play_button_pressed)
	if level_select_button != null and not level_select_button.pressed.is_connected(_on_level_select_button_pressed):
		level_select_button.pressed.connect(_on_level_select_button_pressed)
	if character_select_button != null and not character_select_button.pressed.is_connected(_on_character_select_button_pressed):
		character_select_button.pressed.connect(_on_character_select_button_pressed)
	if options_button != null and not options_button.pressed.is_connected(_on_options_button_pressed):
		options_button.pressed.connect(_on_options_button_pressed)
	if exit_button != null and not exit_button.pressed.is_connected(_on_exit_button_pressed):
		exit_button.pressed.connect(_on_exit_button_pressed)

var damage_numbers_enabled: bool = false

func set_damage_numbers(val: bool) -> void:
	damage_numbers_enabled = val

func _on_play_button_pressed() -> void:
	if get_tree() != null:
		get_tree().paused = false
	var global = _get_global()
	if global != null:
		global.CurrentGameKillCount = 0
		global.CurrentPlayer = null
		global.CurrentLevel = null
		global.CurrentGameUI = null
		if global.CurrentLevelPath == "" or not ResourceLoader.exists(global.CurrentLevelPath):
			global.CurrentLevelPath = "res://assets/levels/castle.tscn"
		var target_scene = global.GameScene if ("GameScene" in global and global.GameScene != "") else "res://scenes/game.tscn"
		if global.has_method("change_scene"):
			global.change_scene("res://assets/scripts/globals/default_transition.tscn", target_scene, "fade_center")
		else:
			get_tree().change_scene_to_file(target_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_level_select_button_pressed() -> void:
	if get_tree() != null:
		get_tree().paused = false
	var global = _get_global()
	var target = "res://scenes/levels.tscn"
	if global != null and "LevelSelectScene" in global and global.LevelSelectScene != "":
		target = global.LevelSelectScene
	elif global != null and "LevelsScene" in global and global.LevelsScene != "":
		target = global.LevelsScene
	if global != null and global.has_method("change_scene"):
		global.change_scene("res://assets/scripts/globals/default_transition.tscn", target, "fade_center")
	else:
		get_tree().change_scene_to_file(target)

func _on_character_select_button_pressed() -> void:
	if get_tree() != null:
		get_tree().paused = false
	var global = _get_global()
	var target = "res://scenes/character_select.tscn"
	if global != null and "CharacterSelectScene" in global and global.CharacterSelectScene != "":
		target = global.CharacterSelectScene
	if global != null and global.has_method("change_scene"):
		global.change_scene("res://assets/scripts/globals/default_transition.tscn", target, "fade_center")
	else:
		get_tree().change_scene_to_file(target)

func _on_options_button_pressed() -> void:
	if get_tree() != null:
		get_tree().paused = false
	var global = _get_global()
	var target = "res://scenes/options_menu.tscn"
	if global != null and "OptionsScene" in global and global.OptionsScene != "":
		target = global.OptionsScene
	if global != null and global.has_method("change_scene"):
		global.change_scene("res://assets/scripts/globals/default_transition.tscn", target, "fade_center")
	else:
		get_tree().change_scene_to_file(target)

func _on_quit_button_pressed() -> void:
	if get_tree() != null:
		get_tree().quit()

func _on_exit_button_pressed() -> void:
	if get_tree() != null:
		get_tree().quit()
