class_name MenuHandler
extends Node

## Menu and Modal Dialog Manager ported from Unity MenuHandler.cs.
## Replicates:
##   Modal dialogs for item pickups and chests with game pause/resume handling (Time.timeScale),
##   Pause menu toggling, ItemSlot generation, and static event pipeline.

signal on_show_pause_menu()
signal on_close_pause_menu()
signal on_show_item(item: Variant)
signal on_show_chest()
signal on_new_item_slot(attribute: Variant)
signal on_take_item(item: Variant)
signal on_take_chest()

# Signal aliases matching Unity event naming convention
signal OnShowPauseMenu()
signal OnClosePauseMenu()
signal OnShowItem(item: Variant)
signal OnShowChest()
signal OnNewItemSlot(attribute: Variant)
signal OnTakeItem(item: Variant)
signal OnTakeChest()

static var instance : MenuHandler = null

static var Instance : MenuHandler:
	get: return instance

@export var chest_menu_scene : PackedScene = preload("res://assets/objects/menus/chest_menu.tscn")
@export var item_menu_scene : PackedScene = preload("res://assets/objects/menus/item_pick_up.tscn")
@export var item_slot_scene : PackedScene = preload("res://assets/objects/menus/slot.tscn") if ResourceLoader.exists("res://assets/objects/menus/slot.tscn") else null

var is_paused : bool = false
var active_pause_menu : Control = null

func _init() -> void:
	Awake()

func _enter_tree() -> void:
	Awake()

func Awake() -> void:
	if instance != null and instance != self and is_instance_valid(instance) and instance.is_inside_tree():
		push_warning("Only one Menu Handler!")
	else:
		instance = self

func _ready() -> void:
	Start()

func Start() -> void:
	var global = _get_global()
	if global != null:
		global.set("CurrentMenuHandler", self)
		
	# Hook events to Pause/Resume pipeline matching Unity:
	on_show_item.connect(_on_item_shown)
	on_show_chest.connect(_on_pause_requested)
	on_take_item.connect(_on_item_taken)
	on_take_chest.connect(_on_resume_requested)
	on_show_pause_menu.connect(_on_pause_requested)
	on_close_pause_menu.connect(_on_resume_requested)

func _on_item_shown(_it: Variant) -> void:
	Pause()

func _on_item_taken(_it: Variant) -> void:
	Resume()

func _on_pause_requested() -> void:
	Pause()

func _on_resume_requested() -> void:
	Resume()

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _get_ui_root() -> Node:
	var global = _get_global()
	if global != null and global.CurrentGameUI != null:
		return global.CurrentGameUI
	if is_inside_tree():
		var canvas = get_tree().root.find_child("GameUI", true, false)
		if canvas != null:
			return canvas
		return get_tree().current_scene
	return self

## Unity Pause() port: Time.timeScale = 0f
func Pause() -> void:
	is_paused = true
	Engine.time_scale = 0.0
	if is_inside_tree():
		get_tree().paused = true

## Unity Resume() port: Time.timeScale = 1f
func Resume() -> void:
	is_paused = false
	Engine.time_scale = 1.0
	if is_inside_tree():
		get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if is_paused:
			ClosePauseMenu()
		else:
			ShowPauseMenu()

## Unity ShowPauseMenu() port
func ShowPauseMenu() -> void:
	if is_paused:
		return
	on_show_pause_menu.emit()
	OnShowPauseMenu.emit()
	Pause()

## Unity ClosePauseMenu() port
func ClosePauseMenu() -> void:
	if not is_paused:
		return
	if active_pause_menu != null and is_instance_valid(active_pause_menu):
		active_pause_menu.queue_free()
		active_pause_menu = null
	on_close_pause_menu.emit()
	OnClosePauseMenu.emit()
	Resume()

## Unity ShowItemMenu(Item item) port
func ShowItemMenu(item: Variant) -> Node:
	on_show_item.emit(item)
	OnShowItem.emit(item)
	
	if item_menu_scene == null:
		return null
		
	var menu = item_menu_scene.instantiate()
	var ui_parent = _get_ui_root()
	if ui_parent != null:
		ui_parent.add_child(menu)
		
	if menu.has_method("show_menu"):
		menu.show_menu(item)
	elif menu.has_node("MarginContainer/VBoxContainer/Name"):
		var item_name = item.name if "name" in item else "Item"
		menu.get_node("MarginContainer/VBoxContainer/Name").text = str(item_name)
		
	var ok_btn = menu.get_node_or_null("MarginContainer/VBoxContainer/OkButton")
	if ok_btn != null:
		ok_btn.pressed.connect(_on_take_item_btn_pressed.bind(item))
		
	Pause()
	return menu

func _on_take_item_btn_pressed(item: Variant) -> void:
	on_take_item.emit(item)
	OnTakeItem.emit(item)
	Resume()

## Unity ShowChestMenu() port
func ShowChestMenu() -> Node:
	on_show_chest.emit()
	OnShowChest.emit()
	
	if chest_menu_scene == null:
		return null
		
	var menu = chest_menu_scene.instantiate()
	var ui_parent = _get_ui_root()
	if ui_parent != null:
		ui_parent.add_child(menu)
		
	if menu.has_method("show_menu"):
		menu.show_menu()
		
	var ok_btn = menu.get_node_or_null("MarginContainer/VBoxContainer/OkButton")
	if ok_btn != null:
		ok_btn.pressed.connect(_on_take_chest_btn_pressed)
		
	Pause()
	return menu

func _on_take_chest_btn_pressed() -> void:
	on_take_chest.emit()
	OnTakeChest.emit()
	Resume()

## Unity NowItemSlot(Attribute attribute) port
func NowItemSlot(attribute: Variant) -> Node:
	return new_item_slot(attribute)

func new_item_slot(attribute: Variant) -> Node:
	on_new_item_slot.emit(attribute)
	OnNewItemSlot.emit(attribute)
	
	if item_slot_scene == null:
		return null
		
	var slot = item_slot_scene.instantiate()
	var ui_parent = _get_ui_root()
	if ui_parent != null:
		ui_parent.add_child(slot)
		
	if "texture" in attribute and slot.has_node("Icon"):
		slot.get_node("Icon").texture = attribute.texture
	return slot
