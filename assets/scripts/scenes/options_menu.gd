extends Control

@export var fps_slider : HSlider
@export var fps_label : Label
@export var volume_slider : HSlider
@export var volume_label : Label

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	if fps_slider != null:
		fps_slider.value = Engine.max_fps
	if fps_label != null and fps_slider != null:
		fps_label.text = str(fps_slider.value) + " FPS:"
		
	if volume_slider == null and has_node("Background/HBoxContainer/VBoxContainer/VolumeSliderContainer/VolumeSlider"):
		volume_slider = get_node("Background/HBoxContainer/VBoxContainer/VolumeSliderContainer/VolumeSlider")
	if volume_label == null and has_node("Background/HBoxContainer/VBoxContainer/VolumeSliderContainer/Label"):
		volume_label = get_node("Background/HBoxContainer/VBoxContainer/VolumeSliderContainer/Label")
		
	if volume_slider != null:
		var bus_idx = AudioServer.get_bus_index("Master")
		if bus_idx >= 0:
			var db = AudioServer.get_bus_volume_db(bus_idx)
			volume_slider.value = db_to_linear(db)
		if volume_label != null:
			volume_label.text = "Volume: %d%%" % int(volume_slider.value * 100)
		volume_slider.value_changed.connect(_on_volume_slider_value_changed)

func _on_back_button_pressed() -> void:
	var global = _get_global()
	if global != null:
		get_tree().change_scene_to_file(global.MainMenuScene)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu_old.tscn")

func _on_h_slider_value_changed(value: float) -> void:
	Engine.max_fps = int(value)
	if fps_label != null:
		fps_label.text = str(int(value)) + " FPS:"

func _on_volume_slider_value_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		if value <= 0.0001:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	if volume_label != null:
		volume_label.text = "Volume: %d%%" % int(value * 100)

func OnVolumeChange(val: float) -> void:
	_on_volume_slider_value_changed(val)
