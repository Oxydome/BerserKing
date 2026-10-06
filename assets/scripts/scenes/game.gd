extends Node

## Main Game Scene Controller
## Manages spawning, round lifecycle, game over transitions, and level setup.

@export var spawn_rate : float = 0.4
@export var spawn_offset : Vector2i = Vector2i(100, 100)

var enemies : Array[PackedScene] = []
var wave_index : int = 0
var max_spawns_per_tick : int = 3

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _get_player() -> Node2D:
	if has_node("Player"):
		return get_node("Player") as Node2D
	var grp = get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	if grp.size() > 0:
		return grp[0] as Node2D
	return null

func _ready() -> void:
	# Keep background pure black in-game
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))

	var global = _get_global()
	var level_node : Node = null
	if global != null and "CurrentLevelPath" in global and global.CurrentLevelPath != "" and ResourceLoader.exists(global.CurrentLevelPath):
		var packed = load(global.CurrentLevelPath)
		if packed != null:
			level_node = packed.instantiate()
			global.CurrentLevel = level_node
	elif global != null and "CurrentLevel" in global and global.CurrentLevel != null:
		var candidate = global.CurrentLevel
		# If candidate already has a parent, instantiate a fresh copy from its scene if possible
		if candidate.get_parent() != null and candidate.scene_file_path != "":
			level_node = load(candidate.scene_file_path).instantiate()
			global.CurrentLevel = level_node
		else:
			level_node = candidate
	
	if level_node == null and ResourceLoader.exists("res://assets/levels/castle.tscn"):
		level_node = load("res://assets/levels/castle.tscn").instantiate()
		if global != null:
			global.CurrentLevel = level_node
			global.CurrentLevelPath = "res://assets/levels/castle.tscn"
	elif level_node == null and ResourceLoader.exists("res://assets/levels/dungeon.tscn"):
		level_node = load("res://assets/levels/dungeon.tscn").instantiate()
		if global != null:
			global.CurrentLevel = level_node
			global.CurrentLevelPath = "res://assets/levels/dungeon.tscn"
	elif level_node == null and ResourceLoader.exists("res://assets/levels/main.tscn"):
		level_node = load("res://assets/levels/main.tscn").instantiate()
		if global != null:
			global.CurrentLevel = level_node
			global.CurrentLevelPath = "res://assets/levels/main.tscn"
			
	if level_node != null:
		if level_node.get_parent() != null:
			level_node.get_parent().remove_child(level_node)
		add_child(level_node)
		move_child(level_node, 1)
		if global != null:
			global.CurrentLevel = level_node
			if "scene_file_path" in level_node and level_node.scene_file_path != "":
				global.CurrentLevelPath = level_node.scene_file_path
			
		var player = _get_player()
		# If level defines a SpawnPoint, position player there first
		if player != null:
			var sp = level_node.get_node_or_null("SpawnPoint")
			if sp != null:
				player.global_position = sp.global_position

		# Verify player is on a walkable tile
		if player != null and level_node is TileMap:
			var tilemap : TileMap = level_node
			var cell = tilemap.local_to_map(player.global_position)
			var source_id = tilemap.get_cell_source_id(0, cell)
			var td = tilemap.get_cell_tile_data(0, cell)
			if source_id == -1 or (td != null and td.get_collision_polygons_count(0) > 0):
				for r in range(1, 50):
					var found = false
					for dx in range(-r, r + 1):
						for dy in range(-r, r + 1):
							var test_cell = cell + Vector2i(dx, dy)
							if tilemap.get_cell_source_id(0, test_cell) != -1:
								var test_td = tilemap.get_cell_tile_data(0, test_cell)
								if test_td != null and test_td.get_collision_polygons_count(0) == 0:
									player.global_position = tilemap.map_to_local(test_cell)
									found = true
									break
						if found:
							break
					if found:
						break
		
	enemies = load_enemies()
	
	if has_node("SpawnTimer"):
		var timer = $SpawnTimer
		if spawn_rate <= 0.0:
			spawn_rate = 1.5
		timer.wait_time = spawn_rate
		if not timer.timeout.is_connected(_on_spawn_timer_timeout):
			timer.timeout.connect(_on_spawn_timer_timeout)
		timer.start()
		
	# Ensure EntityManager is present for wave system
	if not has_node("EntityManager") and EntityManager.instance == null:
		var em = EntityManager.new()
		em.name = "EntityManager"
		if ResourceLoader.exists("res://data/waves/inital_wave.tres"):
			em.waves.append(load("res://data/waves/inital_wave.tres"))
		if ResourceLoader.exists("res://data/waves/general_wave.tres"):
			em.waves.append(load("res://data/waves/general_wave.tres"))
		add_child(em)

func _find_tilemap(node: Node) -> TileMap:
	if node is TileMap:
		return node
	for child in node.get_children():
		var res = _find_tilemap(child)
		if res != null:
			return res
	return null

## Checks whether a world coordinate falls inside the player's visible camera FOV (plus safety margin)
func is_in_player_fov(pos: Vector2, player: Node2D, margin: float = 40.0) -> bool:
	if player == null:
		return false
	var vp_size = Vector2(1152.0, 648.0)
	if player.is_inside_tree() and player.get_viewport() != null:
		var rect = player.get_viewport_rect()
		if rect.size.x > 0 and rect.size.y > 0:
			vp_size = rect.size
			
	var cam = player.get_node_or_null("Camera2D") as Camera2D
	var zoom = cam.zoom if cam != null and cam.zoom.x > 0 and cam.zoom.y > 0 else Vector2.ONE
	var half_w = (vp_size.x / zoom.x) * 0.5 + margin
	var half_h = (vp_size.y / zoom.y) * 0.5 + margin
	
	var cam_pos = cam.get_screen_center_position() if cam != null and cam.is_inside_tree() else player.global_position
	var diff = (pos - cam_pos).abs()
	return diff.x < half_w and diff.y < half_h

func get_walkable_spawn_position(player: Node2D) -> Vector2:
	var tilemap = _find_tilemap(self)
	var space_state = player.get_world_2d().direct_space_state if player.is_inside_tree() else null
	
	var vp_size = Vector2(1152.0, 648.0)
	if player.is_inside_tree() and player.get_viewport() != null:
		var rect = player.get_viewport_rect()
		if rect.size.x > 0 and rect.size.y > 0:
			vp_size = rect.size
			
	var cam = player.get_node_or_null("Camera2D") as Camera2D
	var zoom = cam.zoom if cam != null and cam.zoom.x > 0 and cam.zoom.y > 0 else Vector2.ONE
	var cam_pos = cam.get_screen_center_position() if cam != null and cam.is_inside_tree() else player.global_position
	
	# Safety margin so enemies never pop in at the visible viewport border
	var margin = 60.0
	var half_w = (vp_size.x / zoom.x) * 0.5 + margin
	var half_h = (vp_size.y / zoom.y) * 0.5 + margin
	
	# Sample candidates strictly outside the player's FOV in 4 surrounding perimeter bands
	for depth_range in [[30.0, 200.0], [200.0, 450.0], [450.0, 750.0]]:
		for attempt in range(25):
			var side = randi() % 4
			var extra = randf_range(depth_range[0], depth_range[1])
			var cand = cam_pos
			
			match side:
				0: # Top outside FOV
					cand += Vector2(randf_range(-half_w - 50.0, half_w + 50.0), -half_h - extra)
				1: # Bottom outside FOV
					cand += Vector2(randf_range(-half_w - 50.0, half_w + 50.0), half_h + extra)
				2: # Left outside FOV
					cand += Vector2(-half_w - extra, randf_range(-half_h - 50.0, half_h + 50.0))
				3: # Right outside FOV
					cand += Vector2(half_w + extra, randf_range(-half_h - 50.0, half_h + 50.0))
					
			# Double-check candidate is strictly outside player's FOV
			if is_in_player_fov(cand, player, 20.0):
				continue
				
			if tilemap != null:
				var cell = tilemap.local_to_map(tilemap.to_local(cand))
				if tilemap.get_cell_source_id(0, cell) == -1:
					continue
				var td = tilemap.get_cell_tile_data(0, cell)
				if td != null and td.get_collision_polygons_count(0) > 0:
					continue
					
				# Clearance check in 4 directions so enemies don't spawn half-clipped into walls
				var has_clearance = true
				for off in [Vector2(12, 0), Vector2(-12, 0), Vector2(0, 12), Vector2(0, -12)]:
					var off_cell = tilemap.local_to_map(tilemap.to_local(cand + off))
					if tilemap.get_cell_source_id(0, off_cell) == -1:
						has_clearance = false
						break
					var off_td = tilemap.get_cell_tile_data(0, off_cell)
					if off_td != null and off_td.get_collision_polygons_count(0) > 0:
						has_clearance = false
						break
				if not has_clearance:
					continue
			
			if space_state != null:
				var query = PhysicsPointQueryParameters2D.new()
				query.position = cand
				query.collision_mask = 1
				var hits = space_state.intersect_point(query)
				if hits.size() > 0:
					continue
			
			return cand
			
	# Safe fallback strictly outside player's FOV
	var fallback_angle = randf_range(0.0, TAU)
	var fallback_dist = maxf(half_w, half_h) + 120.0
	return cam_pos + Vector2(cos(fallback_angle), sin(fallback_angle)) * fallback_dist

func load_enemies() -> Array[PackedScene]:
	var enemy_array : Array[PackedScene] = []
	var path = "res://assets/objects/entities/enemies/"
	var dir = DirAccess.open(path)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				var enemy_scene = load(path + file_name)
				if enemy_scene != null:
					enemy_array.append(enemy_scene)
			file_name = dir.get_next()
		dir.list_dir_end()
	return enemy_array

func spawn_enemy() -> void:
	if enemies.size() == 0:
		return
	var player = _get_player()
	if player == null:
		return

	var enemy_scene = enemies[randi() % enemies.size()]
	var enemy_instance = enemy_scene.instantiate()
	var spawn_pos = get_walkable_spawn_position(player)
	
	if has_node("Enemies"):
		$Enemies.add_child(enemy_instance)
	else:
		add_child(enemy_instance)
		
	enemy_instance.global_position = spawn_pos

func _on_spawn_timer_timeout() -> void:
	var count = randi_range(1, max_spawns_per_tick)
	for i in range(count):
		spawn_enemy()
