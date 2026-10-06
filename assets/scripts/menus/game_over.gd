extends Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func show_menu():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var global = _get_global()
	if global != null and global.CurrentGameUI != null and is_instance_valid(global.CurrentGameUI):
		if global.CurrentGameUI.has_menu:
			return false
		else:
			global.CurrentGameUI.has_menu = true
		global.CurrentGameUI.add_child(self)
	else:
		var root = get_tree().current_scene if get_tree() != null else null
		if root != null:
			root.add_child(self)
			
	if has_node("MarginContainer/VBoxContainer/KillCount"):
		var kill_count = global.CurrentGameKillCount if global != null else 0
		$MarginContainer/VBoxContainer/KillCount.text = "You killed " + str(kill_count) + " enemies!"
	if get_tree() != null:
		get_tree().paused = true
	return true

func _on_play_again_pressed() -> void:
	start_new_game()

func start_new_game() -> void:
	visible = false
	if get_tree() != null:
		get_tree().paused = false
	var global = _get_global()
	if global != null:
		global.CurrentGameKillCount = 0
		global.CurrentPlayer = null
		global.CurrentLevel = null
		global.CurrentGameUI = null
		# Preserve global.CurrentLevelPath so the player restarts the exact same level they were playing!
		var target = global.GameScene if ("GameScene" in global and global.GameScene != "") else "res://scenes/game.tscn"
		global.change_scene("res://assets/scripts/globals/default_transition.tscn", target, "fade_center")
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_return_pressed() -> void:
	visible = false
	if get_tree() != null:
		get_tree().paused = false
	var global = _get_global()
	if global != null:
		global.CurrentGameKillCount = 0
		global.CurrentPlayer = null
		global.CurrentLevel = null
		global.CurrentGameUI = null
		# Preserve global.CurrentLevelPath so returning to Main Menu and pressing Play plays the same level!
		if "MainMenuScene" in global and global.MainMenuScene != "":
			get_tree().change_scene_to_file(global.MainMenuScene)
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
