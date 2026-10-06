class_name Enemy
extends CharacterBody2D

## Enemy health tracking and entity destruction ported from Unity Enemy.cs.
## Replicates:
##   public float health = 100f;
##   public void TakeDamage(float damage) { health -= damage; if (health <= 0) Destroy(gameObject); }

signal damaged(amount: float)
signal killed()

@export var speed : int = 100
@export var health : int = 30
@export var damage : int = 20

# Uppercase aliases matching Unity C# naming convention
@warning_ignore("shadowed_global_identifier")
var Health : float:
	get: return float(health)
	set(val): health = int(val)
var Speed : int:
	get: return speed
	set(val): speed = val
var DamageStat : int:
	get: return damage
	set(val): damage = val

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("enemies")
	if has_node("AnimatedSprite2D"):
		var anim = get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim.sprite_frames != null and anim.sprite_frames.has_animation("run"):
			anim.play("run")

func _process(_delta: float) -> void:
	var global = _get_global()
	if global != null and global.CurrentPlayer != null and is_instance_valid(global.CurrentPlayer):
		var pos = global.CurrentPlayer.global_position - global_position
		velocity = (pos).normalized() * speed
		if move_and_slide():
			var last_touch = get_last_slide_collision()
			if last_touch != null:
				var other = last_touch.get_collider()
				if other == global.CurrentPlayer or (other != null and other.is_in_group("player")):
					if other.has_method("DoDamage"):
						other.DoDamage(self)
					elif other.has_method("take_damage"):
						other.take_damage(damage)
					elif "health" in other and other.health:
						other.health -= damage
		
		if has_node("AnimatedSprite2D"):
			get_node("AnimatedSprite2D").flip_h = pos.x <= 0
		
		if health <= 0:
			killed.emit()
			global.CurrentGameKillCount += 1
			queue_free()
		
		if global.CurrentPlayer.global_position.distance_to(global_position) > global.despawn_distance:
			queue_free()

## Unity Enemy.cs TakeDamage(float damage) port
func TakeDamage(damage_amount: float) -> void:
	take_damage(damage_amount)

func take_damage(damage_amount: float) -> void:
	health -= int(damage_amount)
	damaged.emit(damage_amount)
	
	if has_node("AnimatedSprite2D"):
		var anim = get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("get_hit"):
			anim.play("get_hit")
			
	if health <= 0:
		killed.emit()
		var global = _get_global()
		if global != null:
			global.CurrentGameKillCount += 1
		queue_free()
