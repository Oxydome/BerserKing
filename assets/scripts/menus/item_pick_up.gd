extends Control

@export var Text : String = "":
	set(val):
		Text = val
		if label != null:
			label.text = val

var image : TextureRect:
	get:
		if has_node("MarginContainer/VBoxContainer/Image"):
			return get_node("MarginContainer/VBoxContainer/Image") as TextureRect
		elif has_node("Panel/HBoxContainer/VBoxContainer/Image"):
			return get_node("Panel/HBoxContainer/VBoxContainer/Image") as TextureRect
		return null

var label : Label:
	get:
		if has_node("MarginContainer/VBoxContainer/Name"):
			return get_node("MarginContainer/VBoxContainer/Name") as Label
		elif has_node("Panel/HBoxContainer/VBoxContainer/Text"):
			return get_node("Panel/HBoxContainer/VBoxContainer/Text") as Label
		return null

var item : Area2D

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func show_menu(new_item: Area2D):
	var global = _get_global()
	if global != null and global.CurrentGameUI != null:
		if global.CurrentGameUI.has_menu:
			return false
		else:
			global.CurrentGameUI.has_menu = true
		global.CurrentGameUI.add_child(self)
	item = new_item
	if image != null:
		image.texture = item.texture
	if label != null:
		label.text = item.item_name
	get_tree().paused = true
	return true

func _on_ok_button_pressed() -> void:
	var global = _get_global()
	if global != null and global.CurrentGameUI != null:
		if "inventory" in global.CurrentGameUI and global.CurrentGameUI.inventory != null:
			var img_tex = image.texture if image != null else null
			var lbl_txt = label.text if label != null else ""
			global.CurrentGameUI.inventory.add_slot(img_tex, lbl_txt)
		global.CurrentGameUI.has_menu = false
	if item != null and "callback" in item and item.callback != null and item.callback.is_valid():
		item.callback.call()
	get_tree().paused = false
	if item != null and is_instance_valid(item):
		item.queue_free()
	queue_free()

func _on_button_pressed() -> void:
	_on_ok_button_pressed()

func _on_scrap_button_pressed() -> void:
	var global = _get_global()
	if global != null and global.CurrentGameUI != null:
		global.CurrentGameUI.has_menu = false
	get_tree().paused = false
	if item != null and is_instance_valid(item):
		item.queue_free()
	queue_free()
