class_name LevelInfo
extends Control

signal level_selected(path: String)

@export var title : Label

var level : TileMap
var level_path : String = ""

var original_size := scale
var grow_size := Vector2(1.08, 1.08)

var normal_style : StyleBoxFlat
var selected_style : StyleBoxFlat
var status_label : Label
var _is_selecting : bool = false

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ensure_styles() -> void:
	if normal_style == null:
		normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.137, 0.161, 0.204, 0.9)
		normal_style.set_border_width_all(2)
		normal_style.border_color = Color(0.384, 0.490, 0.635, 1.0)
		normal_style.set_corner_radius_all(8)
		normal_style.shadow_size = 4
		normal_style.shadow_offset = Vector2(0, 2)

	if selected_style == null:
		selected_style = StyleBoxFlat.new()
		selected_style.bg_color = Color(0.15, 0.22, 0.18, 0.95)
		selected_style.set_border_width_all(3)
		selected_style.border_color = Color(0.3, 0.85, 0.4, 1.0)
		selected_style.set_corner_radius_all(8)
		selected_style.shadow_size = 6
		selected_style.shadow_offset = Vector2(0, 3)

func _ready() -> void:
	if get_parent() != null:
		name = name + str(get_parent().get_child_count())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	resized.connect(_update_pivot)
	_update_pivot()

	_ensure_styles()

	var vbox = find_child("VBoxContainer", true, false)
	if vbox != null and vbox.get_node_or_null("Status") == null:
		status_label = Label.new()
		status_label.name = "Status"
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_label.add_theme_font_size_override("font_size", 14)
		vbox.add_child(status_label)

	# Add a transparent full-size Button overlay to guarantee 100% click reliability
	if get_node_or_null("ClickButton") == null:
		var btn = Button.new()
		btn.name = "ClickButton"
		btn.flat = true
		btn.anchors_preset = Control.PRESET_FULL_RECT
		btn.anchor_right = 1.0
		btn.anchor_bottom = 1.0
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(select_level)
		btn.mouse_entered.connect(_on_mouse_entered)
		btn.mouse_exited.connect(_on_mouse_exited)
		add_child(btn)

	update_display()

func _update_pivot() -> void:
	pivot_offset = size / 2.0

func update_display() -> void:
	_ensure_styles()

	var global = _get_global()
	var is_cur = false
	if global != null and "CurrentLevelPath" in global:
		is_cur = (global.CurrentLevelPath == level_path)

	if is_cur:
		add_theme_stylebox_override("panel", selected_style)
		if status_label != null:
			status_label.text = "[ SELECTED ]"
			status_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4, 1.0))
	else:
		add_theme_stylebox_override("panel", normal_style)
		if status_label != null:
			status_label.text = "Click to Play"
			status_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.7))

func grow_btn(end_size : Vector2, duration: float) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, 'scale', end_size, duration)

func _gui_input(event: InputEvent) -> void:
	_handle_input(event)

func _on_gui_input(event: InputEvent) -> void:
	_handle_input(event)

func _handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			select_level()
	elif event.is_action_pressed("left_click") or event.is_action_pressed("ui_accept"):
		select_level()

func _on_mouse_entered() -> void:
	grow_btn(grow_size, 0.1)

func _on_mouse_exited() -> void:
	grow_btn(original_size, 0.1)

func select_level() -> void:
	if _is_selecting:
		return
	_is_selecting = true

	var global = _get_global()
	var selected_path = level_path
	if (selected_path == "" or not ResourceLoader.exists(selected_path)) and level != null and "scene_file_path" in level:
		selected_path = level.scene_file_path
	if selected_path == "" or not ResourceLoader.exists(selected_path):
		selected_path = "res://assets/levels/castle.tscn"

	if global != null:
		global.CurrentLevelPath = selected_path
		global.CurrentLevel = null
		global.CurrentGameKillCount = 0
		global.CurrentPlayer = null
		global.CurrentGameUI = null

		level_selected.emit(selected_path)

		var target_scene = global.GameScene if ("GameScene" in global and global.GameScene != "") else "res://scenes/game.tscn"
		if global.has_method("change_scene"):
			global.change_scene("res://assets/scripts/globals/default_transition.tscn", target_scene, "fade_center")
		else:
			get_tree().change_scene_to_file(target_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
