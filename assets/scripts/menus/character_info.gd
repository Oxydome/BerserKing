extends Panel

## Character Information Card in Character Select Menu

signal character_selected(char_path: String)

@export var character_name : String = "Wind Warrior"
@export var character_path : String = "res://assets/textures/sprites/player/windman.tres"
@export var character_desc : String = "Agile ninja blade master harnessing the swift winds."

@onready var name_label : Label = $VBoxContainer/Name
@onready var desc_label : Label = $VBoxContainer/Description
@onready var sprite_preview : AnimatedSprite2D = $VBoxContainer/PreviewControl/AnimatedSprite2D
@onready var select_button : Button = $VBoxContainer/SelectButton

var normal_style : StyleBoxFlat
var selected_style : StyleBoxFlat

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	custom_minimum_size = Vector2(210, 260)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.14, 0.18, 0.9)
	normal_style.set_border_width_all(2)
	normal_style.border_color = Color(0.35, 0.45, 0.6, 1.0)
	normal_style.set_corner_radius_all(8)

	selected_style = StyleBoxFlat.new()
	selected_style.bg_color = Color(0.15, 0.22, 0.18, 0.95)
	selected_style.set_border_width_all(3)
	selected_style.border_color = Color(0.3, 0.85, 0.4, 1.0)
	selected_style.set_corner_radius_all(8)

	update_display()
	
	if select_button != null and not select_button.pressed.is_connected(select_character):
		select_button.pressed.connect(select_character)

func update_display() -> void:
	if name_label != null:
		name_label.text = character_name
	if desc_label != null:
		desc_label.text = character_desc
		
	if sprite_preview != null and ResourceLoader.exists(character_path):
		var sf = load(character_path)
		if sf is SpriteFrames:
			sprite_preview.sprite_frames = sf
			if sf.has_animation("idle"):
				sprite_preview.play("idle")
			elif sf.has_animation("walk"):
				sprite_preview.play("walk")
			elif sf.has_animation("run"):
				sprite_preview.play("run")
				
			var preview_ctrl = get_node_or_null("VBoxContainer/PreviewControl") as Control
			var center = Vector2(95.0, 45.0)
			if preview_ctrl != null and preview_ctrl.size.x > 0 and preview_ctrl.size.y > 0:
				center = preview_ctrl.size * 0.5
				
			# Exact visual centering based on texture frame dimensions and bounding boxes
			if character_path.contains("windman"):
				# 288x128 frame, character visual center offset (+5.0, +44.5) from frame center
				sprite_preview.scale = Vector2(1.8, 1.8)
				sprite_preview.position = center - Vector2(5.0, 44.5) * sprite_preview.scale
			elif character_path.contains("player.tres") or character_path.contains("fireman"):
				# 288x128 frame, character visual center offset (-14.0, +41.0) from frame center
				sprite_preview.scale = Vector2(1.5, 1.5)
				sprite_preview.position = center - Vector2(-14.0, 41.0) * sprite_preview.scale
			elif character_path.contains("player_c"):
				# 48x48 frame, character visual center offset (-1.0, +1.5) from frame center
				sprite_preview.scale = Vector2(2.4, 2.4)
				sprite_preview.position = center - Vector2(-1.0, 1.5) * sprite_preview.scale
			elif character_path.contains("bandit"):
				# 50x37 frame, character visual center offset (-1.5, +2.0) from frame center
				sprite_preview.scale = Vector2(2.4, 2.4)
				sprite_preview.position = center - Vector2(-1.5, 2.0) * sprite_preview.scale
			elif character_path.contains("wizard"):
				# 160x128 frame, character visual center offset (+3.0, +25.0) from frame center
				sprite_preview.scale = Vector2(1.3, 1.3)
				sprite_preview.position = center - Vector2(3.0, 25.0) * sprite_preview.scale
			else:
				sprite_preview.scale = Vector2(1.5, 1.5)
				sprite_preview.position = center

	var global = _get_global()
	var is_cur = false
	if global != null and "CurrentCharacterPath" in global:
		is_cur = (global.CurrentCharacterPath == character_path)

	if is_cur:
		add_theme_stylebox_override("panel", selected_style)
		if select_button != null:
			select_button.text = "Selected"
			select_button.disabled = true
	else:
		add_theme_stylebox_override("panel", normal_style)
		if select_button != null:
			select_button.text = "Select"
			select_button.disabled = false

func select_character() -> void:
	var global = _get_global()
	if global != null:
		global.CurrentCharacterPath = character_path
		global.CurrentCharacterName = character_name
	emit_signal("character_selected", character_path)
