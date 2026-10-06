extends Control

@export var levels_menu : Container
@export_dir var levels_path : String = "res://assets/levels"
@export var level_icon : PackedScene
@export var back_button : Button

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	if back_button != null and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	elif has_node("Panel/HBoxContainer/VBoxContainer/Back"):
		var b = get_node("Panel/HBoxContainer/VBoxContainer/Back") as Button
		if b != null and not b.pressed.is_connected(_on_back_pressed):
			b.pressed.connect(_on_back_pressed)

	populate_levels()

func populate_levels() -> void:
	if levels_menu == null and has_node("Panel/HBoxContainer/VBoxContainer/Levels"):
		levels_menu = get_node("Panel/HBoxContainer/VBoxContainer/Levels")
	if level_icon == null:
		level_icon = load("res://assets/objects/level_info.tscn")
	if levels_menu == null or level_icon == null:
		return

	# Clear any previous child items
	for child in levels_menu.get_children():
		child.queue_free()

	# The canonical playable game levels: Castle (default) and Dungeon
	var known_levels = [
		{
			"title": "Castle",
			"path": "res://assets/levels/castle.tscn"
		},
		{
			"title": "Dungeon",
			"path": "res://assets/levels/dungeon.tscn"
		}
	]

	var added_paths = {
		"res://assets/levels/laval.tscn": true,
		"res://assets/levels/main.tscn": true,
		"res://scenes/lobby.tscn": true
	}

	for entry in known_levels:
		if ResourceLoader.exists(entry.path):
			_create_level_card(entry.title, entry.path)
			added_paths[entry.path] = true
			if entry.path.ends_with("dungeon.tscn"):
				added_paths["res://assets/levels/main.tscn"] = true
			if entry.path.ends_with("castle.tscn"):
				added_paths["res://scenes/lobby.tscn"] = true
				added_paths["res://assets/levels/lobby.tscn"] = true

	# Also scan levels_path for any additional user levels (excluding laval)
	if levels_path != null and levels_path != "":
		var dir = DirAccess.open(levels_path)
		if dir != null:
			dir.list_dir_begin()
			while true:
				var file_name = dir.get_next()
				if file_name == "":
					break
				if file_name.to_lower().contains("laval") or file_name.to_lower().contains("lobby"):
					continue
				if not file_name.begins_with(".") and file_name.ends_with(".tscn"):
					var full_path = levels_path.path_join(file_name)
					if not added_paths.has(full_path):
						var display_title = file_name.get_basename().capitalize()
						_create_level_card(display_title, full_path)
						added_paths[full_path] = true
			dir.list_dir_end()

func _create_level_card(display_title: String, scene_path: String) -> Control:
	var icon = level_icon.instantiate()
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	if "level_path" in icon:
		icon.level_path = scene_path
	if ResourceLoader.exists(scene_path):
		var packed = load(scene_path)
		if packed != null and "level" in icon:
			icon.level = packed.instantiate()
	if icon.get_node_or_null("HBoxContainer/VBoxContainer/Text") != null:
		icon.get_node("HBoxContainer/VBoxContainer/Text").text = display_title
	elif "title" in icon and icon.title != null:
		icon.title.text = display_title
	if icon.has_signal("level_selected"):
		icon.level_selected.connect(_on_level_chosen)
	levels_menu.add_child(icon)
	if icon.has_method("update_display"):
		icon.update_display()
	return icon

func _on_level_chosen(_path: String) -> void:
	if levels_menu != null:
		for card in levels_menu.get_children():
			if card.has_method("update_display"):
				card.update_display()

func _on_back_pressed() -> void:
	var global = _get_global()
	var target = "res://scenes/main_menu_old.tscn"
	if global != null and "MainMenuScene" in global and global.MainMenuScene != "":
		target = global.MainMenuScene
	if global != null and global.has_method("change_scene"):
		global.change_scene("res://assets/scripts/globals/default_transition.tscn", target, "fade_center")
	else:
		get_tree().change_scene_to_file(target)
