class_name ShurikenBullet
extends Area2D

@export var speed : float = 400.0
@export var damage : float = 35.0
@export var lifetime : float = 5.0
@export var rotation_speed : float = 20.0

var direction : Vector2 = Vector2.RIGHT
var _time_alive : float = 0.0

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	# Disappear after exactly 5 seconds
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	_time_alive += delta
	if _time_alive >= lifetime:
		queue_free()
		return
		
	position += direction * speed * delta
	if has_node("Sprite2D"):
		$Sprite2D.rotation += rotation_speed * delta

## Unity/Godot shoot activation
func shoot(dir: Vector2 = Vector2.ZERO) -> void:
	if dir != Vector2.ZERO:
		direction = dir.normalized()
	process_mode = Node.PROCESS_MODE_INHERIT

func _on_body_entered(body: Node2D) -> void:
	var global = _get_global()
	var player = global.CurrentPlayer if global != null else null
	if body == player:
		return
	if body is TileMap:
		return
		
	var damaged = false
	if body.has_method("TakeDamage"):
		body.TakeDamage(damage)
		damaged = true
	elif body.has_method("take_damage"):
		body.take_damage(damage)
		damaged = true
	elif "health" in body:
		body.health -= damage
		damaged = true
		
	if damaged:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	var global = _get_global()
	var player = global.CurrentPlayer if global != null else null
	var parent_node = area.get_parent()
	if parent_node == player or area == player:
		return
		
	var target = parent_node if parent_node != null else area
	if target.has_method("TakeDamage"):
		target.TakeDamage(damage)
		queue_free()
	elif target.has_method("take_damage"):
		target.take_damage(damage)
		queue_free()
	elif "health" in target and not target is TileMap:
		target.health -= damage
		queue_free()
