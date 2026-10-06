class_name ShurikenWeapon
extends Node2D

@export_file("*.tscn") var shuriken_bullet : String = "res://assets/scripts/objects/weapons/shuriken/shuriken_bullet.tscn"
@export var fire_rate : float = 3.0
@export var distance : int = 100
@export var star_count : int = 8
@export var circle_radius : float = 24.0

var current_rotation_offset : float = 0.0

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	if has_node("SpawnTimer"):
		var timer = $SpawnTimer
		timer.wait_time = fire_rate if fire_rate > 0.0 else 3.0
		if not timer.timeout.is_connected(_on_spawn_timer_timeout):
			timer.timeout.connect(_on_spawn_timer_timeout)
		timer.start()
		
	# Fire initial circle of ninja stars on startup
	call_deferred("shoot_circle")

## Shoots a full 360-degree circle of ninja stars around the player
func shoot_circle() -> void:
	var bullet_path = shuriken_bullet if (shuriken_bullet != null and shuriken_bullet != "") else "res://assets/scripts/objects/weapons/shuriken/shuriken_bullet.tscn"
	if not ResourceLoader.exists(bullet_path):
		return
	var bullet_packed = load(bullet_path)
	if bullet_packed == null:
		return
		
	var scene_root = get_tree().current_scene if is_inside_tree() else null
	var parent_node = get_parent()
	var center_pos = global_position
	
	var count = max(star_count, 1)
	var angle_step = TAU / float(count)
	
	for i in range(count):
		var angle = current_rotation_offset + (i * angle_step)
		var dir = Vector2(cos(angle), sin(angle)).normalized()
		var spawn_pos = center_pos + dir * circle_radius
		
		var new_bullet = bullet_packed.instantiate()
		if new_bullet == null:
			continue
			
		if scene_root != null:
			scene_root.add_child(new_bullet)
		elif parent_node != null and parent_node.get_parent() != null:
			parent_node.get_parent().add_child(new_bullet)
		elif parent_node != null:
			parent_node.add_sibling(new_bullet)
		else:
			add_child(new_bullet)
			
		new_bullet.global_position = spawn_pos
		if new_bullet.has_method("shoot"):
			new_bullet.shoot(dir)
			
	# Advance slight rotation offset between bursts for beautiful radial spiral
	current_rotation_offset = fmod(current_rotation_offset + (angle_step * 0.25), TAU)

## Preserved single-star shoot method for backwards compatibility
func shoot_star(throw_dir: Vector2 = Vector2.RIGHT) -> Node:
	var bullet_path = shuriken_bullet if (shuriken_bullet != null and shuriken_bullet != "") else "res://assets/scripts/objects/weapons/shuriken/shuriken_bullet.tscn"
	if not ResourceLoader.exists(bullet_path):
		return null
	var bullet_packed = load(bullet_path)
	if bullet_packed == null:
		return null
	var new_bullet = bullet_packed.instantiate()
	if new_bullet == null:
		return null
		
	var scene_root = get_tree().current_scene if is_inside_tree() else null
	var parent_node = get_parent()
	if scene_root != null:
		scene_root.add_child(new_bullet)
	elif parent_node != null:
		parent_node.add_sibling(new_bullet)
	else:
		add_child(new_bullet)
		
	new_bullet.global_position = global_position
	if new_bullet.has_method("shoot"):
		new_bullet.shoot(throw_dir)
	return new_bullet

func _on_spawn_timer_timeout() -> void:
	shoot_circle()

func _process(delta: float) -> void:
	var global = _get_global()
	if global != null and global.CurrentPlayer != null and is_instance_valid(global.CurrentPlayer):
		pass
