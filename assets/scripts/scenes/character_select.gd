extends Control

## Character Selection Screen
## Allows the player to browse and select their hero before entering battle.

@export var character_card_scene : PackedScene = preload("res://assets/objects/menus/character_info.tscn")
@export var characters_container : Container
@export var back_button : Button

const CHARACTERS = [
	{
		"name": "Wind Warrior",
		"path": "res://assets/textures/sprites/player/windman.tres",
		"desc": "Agile ninja blade master harnessing swift wind arts and shurikens."
	},
	{
		"name": "Fire Warrior",
		"path": "res://assets/textures/sprites/player/player.tres",
		"desc": "Fierce berserker empowered with flaming greatsword fury."
	},
	{
		"name": "Hero Knight",
		"path": "res://assets/textures/sprites/player_c/player_c.tres",
		"desc": "Valiant knight experienced in martial defense and balanced combat."
	},
	{
		"name": "Rogue",
		"path": "res://assets/textures/sprites/bandit/bandit.tres",
		"desc": "Stealthy hooded assassin striking swiftly from the shadows."
	},
	{
		"name": "Wizard",
		"path": "res://assets/textures/sprites/wizard/wizard.tres",
		"desc": "Mystic spellcaster commanding ancient esoteric energies."
	}
]

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

	populate_characters()

func populate_characters() -> void:
	if characters_container == null and has_node("Panel/HBoxContainer/VBoxContainer/Characters"):
		characters_container = get_node("Panel/HBoxContainer/VBoxContainer/Characters")
	if characters_container == null:
		return

	for child in characters_container.get_children():
		child.queue_free()

	for char_data in CHARACTERS:
		if ResourceLoader.exists(char_data.path):
			var card = character_card_scene.instantiate()
			card.character_name = char_data.name
			card.character_path = char_data.path
			card.character_desc = char_data.desc
			card.character_selected.connect(_on_character_chosen)
			characters_container.add_child(card)

func _on_character_chosen(_path: String) -> void:
	if characters_container != null:
		for card in characters_container.get_children():
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
