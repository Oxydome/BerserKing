class_name ItemManager
extends Node2D

## Dynamic Item & Reflection Upgrade Engine ported from Unity ItemManager.cs.
## Handles procedural item spawning across chunks with obstacle avoidance (Physics.OverlapSphere equivalent),
## and dynamic reflection-based stat upgrades targeting entity components at runtime.

const ItemLevelScript = preload("res://assets/scripts/classes/item_level.gd")

signal item_spawned(item: Node2D)
signal new_item_spawned(item: ItemResource)
signal item_despawned(item: Node2D)
signal item_picked_up(item: Node2D, who_picked_up: Node2D)

# Uppercase signal aliases matching Unity C# event names
signal OnItemSpawned(item: Node2D)
signal OnNewItemSpawned(item: ItemResource)
signal OnItemDespawned(item: Node2D)
signal OnItemPickUpEvent(item: Node2D, who_picked_up: Node2D)

static var instance : ItemManager
static var Instance : ItemManager:
	get: return instance

@export_group("Items & Generation")
@export var items : Array = [] # Untyped Array to accept any item array
@export var chunk_x : int = 512
@export var chunk_y : int = 512
@export var max_item_amount : int = 5
@export var obstacle_collision_mask : int = 1
@export var obstacle_avoidance_radius : float = 24.0

# Uppercase property aliases matching Unity C# naming convention
var Items : Array:
	get: return items
	set(val): items = val
var ChunkX : int:
	get: return chunk_x
	set(val): chunk_x = val
var ChunkY : int:
	get: return chunk_y
	set(val): chunk_y = val
var MaxItemAmount : int:
	get: return max_item_amount
	set(val): max_item_amount = val

# Dictionary storing spawned items per chunk:
# Key: Vector2i(chunk_x, chunk_y) -> Value: Array of Dictionary { "pos": Vector2, "id": int }
var spawned_items : Dictionary = {}
var SpawnedItems : Dictionary:
	get: return spawned_items
	set(val): spawned_items = val

# Dictionary tracking active item Node2D instances per chunk
# Key: Vector2i(chunk_x, chunk_y) -> Value: Array of Node2D
var _active_chunk_nodes : Dictionary = {}

func _enter_tree() -> void:
	if instance == null:
		instance = self
	var global = get_node_or_null("/root/Global")
	if global != null:
		global.CurrentItemManager = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	if instance == null:
		instance = self
		
	var global = get_node_or_null("/root/Global")
	if global != null:
		global.CurrentItemManager = self
		if global.has_signal("generate_on_new_loaded"):
			global.generate_on_new_loaded.connect(_on_global_new_chunk_loaded)
		if global.has_signal("generate_on_loaded"):
			global.generate_on_loaded.connect(_on_global_chunk_loaded)
		if global.has_signal("generate_on_unloaded"):
			global.generate_on_unloaded.connect(_on_global_chunk_unloaded)

#region Signal Handlers for Generator.gd
func _on_global_new_chunk_loaded(pos: Vector2i, _tile) -> void:
	var cx = int(floor(float(pos.x) / float(chunk_x))) if chunk_x != 0 else pos.x
	var cy = int(floor(float(pos.y) / float(chunk_y))) if chunk_y != 0 else pos.y
	OnNewLoadChunk(cx, cy)

func _on_global_chunk_loaded(pos: Vector2i, _tile) -> void:
	var cx = int(floor(float(pos.x) / float(chunk_x))) if chunk_x != 0 else pos.x
	var cy = int(floor(float(pos.y) / float(chunk_y))) if chunk_y != 0 else pos.y
	OnLoadChunk(cx, cy)

func _on_global_chunk_unloaded(pos: Vector2i, _tile) -> void:
	var cx = int(floor(float(pos.x) / float(chunk_x))) if chunk_x != 0 else pos.x
	var cy = int(floor(float(pos.y) / float(chunk_y))) if chunk_y != 0 else pos.y
	OnUnloadChunk(cx, cy)
#endregion

## Checks if a world position is obstructed by terrain, walls, or solid colliders.
## Equivalent to Unity Physics.OverlapSphere != null check.
func is_position_obstructed(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	if space_state == null:
		return false
		
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = obstacle_avoidance_radius
	query.shape = circle
	query.transform = Transform2D(0.0, pos)
	query.collision_mask = obstacle_collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	
	var results = space_state.intersect_shape(query, 1)
	return results.size() > 0

## Unity OnNewLoadChunk(int x, int y) port
func OnNewLoadChunk(x: int, y: int) -> void:
	if items.is_empty():
		return
		
	var chunk_key = Vector2i(x, y)
	if not spawned_items.has(chunk_key):
		spawned_items[chunk_key] = []
		
	var item_amount = randi_range(0, max_item_amount)
	var chunk_origin = Vector2(float(x * chunk_x), float(y * chunk_y))
	
	for i in range(item_amount):
		var random_item : ItemResource = items.pick_random() as ItemResource
		if random_item == null:
			continue
			
		# Find a free position that is not obstructed by obstacles
		var found_pos = Vector2.ZERO
		var valid_spawn = false
		for attempt in range(10):
			var candidate = Vector2(
				randf_range(chunk_origin.x, chunk_origin.x + float(chunk_x)),
				randf_range(chunk_origin.y, chunk_origin.y + float(chunk_y))
			)
			if not is_position_obstructed(candidate):
				found_pos = candidate
				valid_spawn = true
				break
				
		if not valid_spawn:
			continue
			
		# Spawn the item node
		var item_node = _spawn_item_node(random_item, found_pos)
		
		# Record to chunk data
		spawned_items[chunk_key].append({
			"id": random_item.ID,
			"pos": found_pos
		})
		
		if not _active_chunk_nodes.has(chunk_key):
			_active_chunk_nodes[chunk_key] = []
		_active_chunk_nodes[chunk_key].append(item_node)
		
		new_item_spawned.emit(random_item)
		OnNewItemSpawned.emit(random_item)

## Unity OnLoadChunk(int x, int y) port
func OnLoadChunk(x: int, y: int) -> void:
	var chunk_key = Vector2i(x, y)
	if not spawned_items.has(chunk_key):
		return
		
	# Clear any previous active nodes for this chunk
	if _active_chunk_nodes.has(chunk_key):
		for node in _active_chunk_nodes[chunk_key]:
			if is_instance_valid(node):
				node.queue_free()
		_active_chunk_nodes[chunk_key].clear()
	else:
		_active_chunk_nodes[chunk_key] = []
		
	var records : Array = spawned_items[chunk_key]
	for record in records:
		var item_id : int = record.get("id", 0)
		var pos : Vector2 = record.get("pos", Vector2.ZERO)
		var item_resource = get_item_by_id(item_id)
		if item_resource != null:
			var node = _spawn_item_node(item_resource, pos)
			_active_chunk_nodes[chunk_key].append(node)

## Unity OnUnloadChunk(int x, int y) port
func OnUnloadChunk(x: int, y: int) -> void:
	var chunk_key = Vector2i(x, y)
	if _active_chunk_nodes.has(chunk_key):
		for node in _active_chunk_nodes[chunk_key]:
			if is_instance_valid(node):
				node.queue_free()
				item_despawned.emit(node)
				OnItemDespawned.emit(node)
		_active_chunk_nodes.erase(chunk_key)

## Instantiates and attaches visual & physics components for an item
func _spawn_item_node(item: ItemResource, pos: Vector2) -> Node2D:
	var item_area = Area2D.new()
	item_area.name = "Item_%s" % item.Name
	item_area.position = pos
	item_area.set_meta("item_data", item)
	
	# Sprite2D
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var tex = item.Texture if ("Texture" in item and item.Texture != null) else (item.texture if "texture" in item else null)
	if tex != null:
		sprite.texture = tex
		item_area.set("texture", tex)
	sprite.z_index = 100
	item_area.add_child(sprite)
	
	# Collision Shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 16.0
	collision.shape = shape
	item_area.add_child(collision)
	
	# Audio Stream Player
	var audio = AudioStreamPlayer2D.new()
	audio.name = "AudioStreamPlayer2D"
	if item.PlayOnPickUp != null:
		audio.stream = item.PlayOnPickUp
	item_area.add_child(audio)
	
	# Connect trigger
	item_area.body_entered.connect(_on_item_area_body_entered.bind(item_area))
	
	add_child(item_area)
	item_spawned.emit(item_area)
	OnItemSpawned.emit(item_area)
	return item_area

func _on_item_area_body_entered(body: Node2D, item_area_node: Node2D) -> void:
	OnItemPickUp(item_area_node, body)

## Handles item pickup, audio, and C# reflection-based stat level-up.
## Replicates Unity ItemManager.OnItemPickUp logic.
func OnItemPickUp(item_node: Node2D, who: Node2D) -> void:
	if item_node == null or not is_instance_valid(item_node):
		return
	if who == null or not is_instance_valid(who):
		return
		
	var item_data : ItemResource = null
	if item_node.has_meta("item_data"):
		item_data = item_node.get_meta("item_data") as ItemResource
	elif "item_data" in item_node:
		item_data = item_node.get("item_data") as ItemResource
		
	if item_data == null:
		return
		
	# Play pickup audio
	var audio = item_node.get_node_or_null("AudioStreamPlayer2D") as AudioStreamPlayer2D
	if audio != null and audio.stream != null:
		audio.play()
		
	# Get or attach ItemLevel tracker on the player
	var item_level = who.get_node_or_null("ItemLevel")
	if item_level == null:
		item_level = ItemLevelScript.new()
		item_level.name = "ItemLevel"
		who.add_child(item_level)
		
	# Dynamic Reflection Upgrade System
	if item_data is Attribute or "levels" in item_data or "Levels" in item_data:
		var levels = item_data.get("levels") if "levels" in item_data else item_data.get("Levels")
		if levels != null and levels.size() > 0:
			var current_lvl_idx = item_level.get_level(item_data.ID)
			if current_lvl_idx < levels.size():
				var level_data = levels[current_lvl_idx]
				var states = level_data.get("states") if "states" in level_data else level_data.get("States")
				if states != null:
					for stat in states:
						var comp_name = stat.get("component_name") if "component_name" in stat else stat.get("ComponentName")
						var stat_name = stat.get("stat_name") if "stat_name" in stat else stat.get("StatName")
						var stat_value = stat.get("value") if "value" in stat else stat.get("Value")
						var overwrite = stat.get("overwrite") if "overwrite" in stat else stat.get("OverWrite")
						apply_stat_reflection(who, comp_name, stat_name, stat_value, overwrite)
				item_level.increment_level(item_data.ID)
				
	# Show existing UI popup menu if available
	_show_ui_menu(item_node, item_data)
	
	# Remove item record from chunk data
	_remove_item_from_chunk_data(item_node.position, item_data.ID)
	
	item_picked_up.emit(item_node, who)
	OnItemPickUpEvent.emit(item_node, who)
	item_node.queue_free()

## Helper to display the existing Godot item pickup menu popup
func _show_ui_menu(item_node: Node2D, _item_data: ItemResource) -> void:
	var global = get_node_or_null("/root/Global")
	if global != null and global.CurrentGameUI != null:
		var menu_scene = load("res://assets/objects/menus/item_pick_up.tscn")
		if menu_scene != null:
			var menu = menu_scene.instantiate()
			menu.show_menu(item_node)

func _remove_item_from_chunk_data(pos: Vector2, item_id: int) -> void:
	var cx = int(floor(pos.x / float(chunk_x))) if chunk_x != 0 else int(pos.x)
	var cy = int(floor(pos.y / float(chunk_y))) if chunk_y != 0 else int(pos.y)
	var chunk_key = Vector2i(cx, cy)
	if spawned_items.has(chunk_key):
		var list : Array = spawned_items[chunk_key]
		for i in range(list.size() - 1, -1, -1):
			var rec = list[i]
			if rec.get("id") == item_id and rec.get("pos").distance_to(pos) < 32.0:
				list.remove_at(i)
				break

func get_item_by_id(p_id: int) -> ItemResource:
	for item in items:
		if item.ID == p_id:
			return item
	return null

#region C# Dynamic Reflection System Port
## Dynamically modifies a target component variable using Godot reflection.
## Replicates:
##   Component component = other.GetComponent(Type.GetType(stat.ComponentName, false));
##   FieldInfo property = component.GetType().GetField(stat.StatName);
##   property.SetValue(component, stat.OverWrite ? Convert.ChangeType(stat.Value, ...) : stat.Value + ...);
static func apply_stat_reflection(target_root: Node, component_name: String, stat_name: String, raw_value: Variant, overwrite: bool) -> bool:
	if target_root == null:
		return false
		
	var target_comp = find_component(target_root, component_name)
	if target_comp == null:
		push_warning("ItemManager Reflection: Component '%s' not found on %s" % [component_name, target_root.name])
		return false
		
	# Format stat name for GDScript (try both lowercase and exact case)
	var prop = stat_name
	if not (prop in target_comp):
		prop = stat_name.to_snake_case()
	if not (prop in target_comp):
		prop = stat_name.to_lower()
	if not (prop in target_comp):
		push_warning("ItemManager Reflection: Property '%s' not found on component '%s'" % [stat_name, component_name])
		return false
		
	var current_val = target_comp.get(prop)
	var new_val = raw_value
	if not overwrite and current_val != null:
		# Additive upgrade
		if typeof(current_val) == TYPE_INT:
			new_val = int(current_val) + int(raw_value)
		elif typeof(current_val) == TYPE_FLOAT:
			new_val = float(current_val) + float(raw_value)
		else:
			new_val = raw_value
	else:
		if typeof(current_val) == TYPE_INT:
			new_val = int(raw_value)
		elif typeof(current_val) == TYPE_FLOAT:
			new_val = float(raw_value)
			
	target_comp.set(prop, new_val)
	return true

## Searches target node hierarchy for a component / child / script matching component_name
static func find_component(node: Node, comp_name: String) -> Node:
	if node == null:
		return null
		
	# Direct match on root
	if node.name.to_lower() == comp_name.to_lower() or (node.get_script() != null and node.get_script().resource_path.get_file().get_basename().to_lower() == comp_name.to_lower()):
		return node
		
	# Match children
	for child in node.get_children():
		if child.name.to_lower() == comp_name.to_lower():
			return child
		if child.get_script() != null and child.get_script().resource_path.get_file().get_basename().to_lower() == comp_name.to_lower():
			return child
			
	return null
#endregion
