class_name EntityManager
extends Node

## Entity & Wave Spawning Manager ported from Unity EntityManager.cs.
## Replicates:
##   public int EntityLimit = 200;
##   public List<Wave> waves;
##   private List<GameObject> Entitys;
##   public static EntityManager Instance { get; private set; }
##   Spawn(Entity data), Spawer()

signal entity_spawned(entity: Node)
signal entity_despawned(entity: Node)
signal wave_started(wave: WaveResource)
signal wave_ended(wave: WaveResource)

# Signal aliases matching Unity event naming
signal OnEntitySpawned(entity: Node)
signal OnEntityDespawned(entity: Node)
signal OnWaveStarted(wave: WaveResource)
signal OnWaveEnded(wave: WaveResource)

static var instance : EntityManager = null

# Uppercase Instance accessor
static var Instance : EntityManager:
	get: return instance

@export var entity_limit : int = 200
@export var waves : Array[WaveResource] = []
@export var loop_waves : bool = true
@export var spawn_radius_min : float = 650.0
@export var spawn_radius_max : float = 900.0
@export var default_enemy_scene : PackedScene = preload("res://assets/objects/entities/enemies/worm.tscn")

var entities : Array[Node] = []
var is_spawning : bool = false
var current_wave_index : int = 0

# Uppercase aliases matching Unity C# naming convention
var EntityLimit : int:
	get: return entity_limit
	set(val): entity_limit = val

var Waves : Array[WaveResource]:
	get: return waves
	set(val): waves = val

var Entitys : Array[Node]:
	get: return entities

func _init() -> void:
	Awake()

func _enter_tree() -> void:
	Awake()

func _exit_tree() -> void:
	is_spawning = false
	if instance == self:
		instance = null

func _ready() -> void:
	Start()

func Awake() -> void:
	if instance != null and instance != self and is_instance_valid(instance) and instance.is_inside_tree():
		pass
	else:
		instance = self

func Start() -> void:
	# Register with Global if available
	var global = _get_global()
	if global != null:
		global.set("CurrentEntityManager", self)
		
	start_spawner()

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _find_tilemap(node: Node) -> TileMap:
	if node == null:
		return null
	if node is TileMap:
		return node
	for child in node.get_children():
		var res = _find_tilemap(child)
		if res != null:
			return res
	return null

## Checks whether a world coordinate falls inside the player's visible camera FOV (plus safety margin)
func is_in_player_fov(pos: Vector2, player: Node2D, margin: float = 40.0) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var cam: Camera2D = null
	if player.has_node("Camera2D"):
		cam = player.get_node("Camera2D") as Camera2D
	elif player.is_inside_tree() and player.get_viewport() != null:
		cam = player.get_viewport().get_camera_2d()
	
	var view_size = Vector2(1152, 648)
	var cam_pos = player.global_position
	var zoom = Vector2.ONE
	if cam != null:
		cam_pos = cam.get_screen_center_position()
		zoom = cam.zoom
		if zoom.x <= 0.001 or zoom.y <= 0.001:
			zoom = Vector2.ONE
	if player.is_inside_tree() and player.get_viewport() != null:
		view_size = player.get_viewport_rect().size

	var half_w = (view_size.x / (2.0 * zoom.x)) + margin
	var half_h = (view_size.y / (2.0 * zoom.y)) + margin

	var in_x = abs(pos.x - cam_pos.x) <= half_w
	var in_y = abs(pos.y - cam_pos.y) <= half_h
	return in_x and in_y

## Finds a walkable tile position around the player strictly outside the camera FOV
func get_walkable_spawn_position(player: Node2D) -> Vector2:
	var root_node = player.get_tree().current_scene if (player.is_inside_tree() and player.get_tree() != null) else player.get_parent()
	var tilemap = _find_tilemap(root_node)

	# Calculate minimum distance that clears the camera FOV in any direction
	var min_clear_dist = spawn_radius_min
	var cam: Camera2D = null
	if player.has_node("Camera2D"):
		cam = player.get_node("Camera2D") as Camera2D
	elif player.is_inside_tree() and player.get_viewport() != null:
		cam = player.get_viewport().get_camera_2d()
	if cam != null and player.is_inside_tree() and player.get_viewport() != null:
		var half_diag = (player.get_viewport_rect().size / (2.0 * cam.zoom)).length()
		min_clear_dist = max(spawn_radius_min, half_diag + 40.0)

	var effective_max = max(spawn_radius_max, min_clear_dist + 250.0)

	if tilemap != null:
		var used_rect = tilemap.get_used_rect()
		var tile_size = tilemap.tile_set.tile_size if tilemap.tile_set != null else Vector2i(64, 64)
		for attempt in range(40):
			var angle = randf_range(0.0, TAU)
			var dist = randf_range(min_clear_dist, effective_max)
			var candidate = player.global_position + Vector2(cos(angle), sin(angle)) * dist
			if is_in_player_fov(candidate, player):
				continue
			var map_pos = tilemap.local_to_map(tilemap.to_local(candidate))
			if used_rect.has_point(map_pos):
				var tile_data = tilemap.get_cell_tile_data(0, map_pos)
				if tile_data != null:
					return candidate
		for cell in tilemap.get_used_cells(0):
			var cell_world = tilemap.to_global(tilemap.map_to_local(cell))
			var dist = cell_world.distance_to(player.global_position)
			if dist >= min_clear_dist and dist <= effective_max and not is_in_player_fov(cell_world, player):
				return cell_world

	for attempt in range(40):
		var angle = randf_range(0.0, TAU)
		var dist = randf_range(min_clear_dist, effective_max)
		var candidate = player.global_position + Vector2(cos(angle), sin(angle)) * dist
		if not is_in_player_fov(candidate, player):
			return candidate

	var fallback_angle = randf_range(0.0, TAU)
	return player.global_position + Vector2(cos(fallback_angle), sin(fallback_angle)) * min_clear_dist

## Unity public void Spawn(Entity data) port
func Spawn(data: Variant) -> Node:
	if entities.size() >= entity_limit:
		return null
		
	var new_entity : Node = null
	
	if data is PackedScene:
		new_entity = data.instantiate()
	elif data is EntityResource:
		var enemy_scene = preload("res://assets/objects/entities/enemies/worm.tscn")
		if data.scene != null:
			new_entity = data.scene.instantiate()
		elif enemy_scene != null:
			var enemy = enemy_scene.instantiate()
			if "health" in enemy:
				enemy.health = data.health
			if "speed" in enemy:
				enemy.speed = int(data.speed)
			if "damage" in enemy:
				enemy.damage = data.damage
			new_entity = enemy
		else:
			# Fallback if no scene: create base Enemy CharacterBody2D
			var enemy = Enemy.new()
			enemy.health = data.health
			enemy.speed = int(data.speed)
			enemy.damage = data.damage
			
			var frames = data.sprite_frames
			if frames != null:
				var anim = AnimatedSprite2D.new()
				anim.name = "AnimatedSprite2D"
				anim.sprite_frames = frames
				if frames.has_animation("run"):
					anim.animation = "run"
					anim.play("run")
				elif frames.has_animation("default"):
					anim.animation = "default"
					anim.play("default")
				enemy.add_child(anim)
				
			var col = CollisionShape2D.new()
			col.name = "CollisionShape2D"
			var circle = CircleShape2D.new()
			circle.radius = 16.0
			col.shape = circle
			enemy.add_child(col)
			
			new_entity = enemy
	elif data is String:
		var res = load(data)
		if res is PackedScene:
			new_entity = res.instantiate()
	elif default_enemy_scene != null:
		new_entity = default_enemy_scene.instantiate()
		
	if new_entity == null:
		return null
		
	# Ensure in enemy groups
	if not new_entity.is_in_group("enemy"):
		new_entity.add_to_group("enemy")
	if not new_entity.is_in_group("enemies"):
		new_entity.add_to_group("enemies")
		
	# Determine spawn position around player
	var player = _get_player()
	var spawn_pos = Vector2.ZERO
	if player != null:
		spawn_pos = get_walkable_spawn_position(player)
	else:
		var angle = randf_range(0.0, TAU)
		var dist = randf_range(spawn_radius_min, spawn_radius_max)
		spawn_pos = Vector2(cos(angle), sin(angle)) * dist
	
	if new_entity is Node2D:
		new_entity.global_position = spawn_pos
		
	# Add to scene hierarchy
	if is_inside_tree():
		var parent_node = get_parent()
		if parent_node != null and parent_node.has_node("Enemies"):
			parent_node.get_node("Enemies").add_child(new_entity)
		elif parent_node != null:
			parent_node.add_child(new_entity)
		else:
			add_child(new_entity)
	else:
		add_child(new_entity)
		
	entities.append(new_entity)
	
	# Connect cleanup when entity despawns / dies
	new_entity.tree_exited.connect(_on_entity_tree_exited.bind(new_entity))
	
	entity_spawned.emit(new_entity)
	OnEntitySpawned.emit(new_entity)
	return new_entity

func _on_entity_tree_exited(ent: Node) -> void:
	if ent != null:
		entities.erase(ent)
		entity_despawned.emit(ent)
		OnEntityDespawned.emit(ent)

func start_spawner() -> void:
	if not is_spawning:
		is_spawning = true
		Spawer()

## Unity private IEnumerator Spawer() port
func Spawer() -> void:
	if waves.is_empty():
		if ResourceLoader.exists("res://data/waves/inital_wave.tres"):
			waves.append(load("res://data/waves/inital_wave.tres"))
		if ResourceLoader.exists("res://data/waves/general_wave.tres"):
			waves.append(load("res://data/waves/general_wave.tres"))
			
	if waves.is_empty():
		return
		
	while is_spawning:
		for wave in waves:
			if not is_spawning:
				break
			wave_started.emit(wave)
			OnWaveStarted.emit(wave)
			
			var wave_limit = wave.MaxEntitys if wave.MaxEntitys > 0 else entity_limit
			var spawn_delay = wave.wave_spawn_cooldown if wave.wave_spawn_cooldown > 0.0 else 0.5
			
			for entry in wave.entities:
				if not is_spawning:
					break
				var to_spawn = entry.Amount
				while to_spawn > 0 and is_spawning:
					if entities.size() < min(entity_limit, wave_limit):
						Spawn(entry.entity)
						to_spawn -= 1
						
					var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
					if tree != null:
						await tree.create_timer(spawn_delay).timeout
					else:
						break
						
			wave_ended.emit(wave)
			OnWaveEnded.emit(wave)
			
		if not loop_waves:
			break

func stop_spawner() -> void:
	is_spawning = false

func _get_player() -> Node2D:
	var global = _get_global()
	if global != null and global.CurrentPlayer != null and is_instance_valid(global.CurrentPlayer):
		return global.CurrentPlayer as Node2D
	if is_inside_tree():
		var tree = get_tree()
		if tree != null:
			var players = tree.get_nodes_in_group("player")
			if players.size() > 0:
				return players[0] as Node2D
	return null
