extends Area2D

@export var item_name : String
@export var texture : Texture
@export_enum("Item", "Weapon") var type = 0
@export var item_data : ItemResource

var item_menu = "res://assets/objects/menus/item_pick_up.tscn"
var callback : Callable

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	if item_name == "":
		item_name = name

func _on_body_entered(body: Node2D) -> void:
	if item_data != null and ItemManager.Instance != null:
		ItemManager.Instance.OnItemPickUp(self, body)
		return
		
	var new_item_menu = load(item_menu).instantiate()
	match type:
		0:
			callback = func(): pass
		1:
			callback = func():
				print(item_name)
				if item_name != "Bow":
					return
				var bow = load("res://assets/objects/weapons/bow/bow.tscn").instantiate()
				var global = _get_global()
				var player = global.CurrentPlayer if global != null else null
				if player != null and !player.has_node("Bow"):
					player.add_child(bow)
	new_item_menu.show_menu(self)
