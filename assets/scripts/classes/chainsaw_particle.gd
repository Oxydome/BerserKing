class_name ChainsawParticle
extends Area2D

## Particle collision damage triggers ported from Unity Chainsaw_Particle.cs.
## Deals damage to enemies on collision with a hit cooldown pipeline.

signal hit_enemy(enemy: Node, damage_dealt: float)

@export var damage : float = 10.0
@export var hit_cooldown : float = 0.5
@export var spin_speed : float = 720.0 # Degrees per second for saw blade sprite spin

var time_since_last_hit : float = 0.0

# Uppercase aliases matching Unity C# naming convention
var Damage : float:
	get: return damage
	set(val): damage = val
var HitCooldown : float:
	get: return hit_cooldown
	set(val): hit_cooldown = val
var TimeSinceLastHit : float:
	get: return time_since_last_hit
	set(val): time_since_last_hit = val

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	Update(delta)

## Unity Update() logic updating time elapsed since last hit
func Update(delta: float) -> void:
	time_since_last_hit += delta
	
	# Visual spin for saw blade
	if has_node("Sprite2D"):
		get_node("Sprite2D").rotation += deg_to_rad(spin_speed * delta)
		
	# Continuous contact damage for overlapping bodies
	if time_since_last_hit >= hit_cooldown:
		for body in get_overlapping_bodies():
			if _can_damage(body):
				OnParticleCollision(body)
				break

func _on_body_entered(body: Node2D) -> void:
	if _can_damage(body):
		OnParticleCollision(body)

func _on_area_entered(area: Area2D) -> void:
	var target = area.get_parent() if area.get_parent() != null else area
	if _can_damage(target):
		OnParticleCollision(target)

func _can_damage(target: Node) -> bool:
	if target == null:
		return false
	var global = get_node_or_null("/root/Global")
	if global != null and target == global.CurrentPlayer:
		return false
	return target.has_method("TakeDamage") or target.has_method("take_damage") or "health" in target

## Unity OnParticleCollision(GameObject other) logic
func OnParticleCollision(other: Node) -> void:
	if time_since_last_hit >= hit_cooldown:
		if other.has_method("TakeDamage"):
			other.TakeDamage(damage)
			hit_enemy.emit(other, damage)
		elif other.has_method("take_damage"):
			other.take_damage(damage)
			hit_enemy.emit(other, damage)
		elif "health" in other:
			other.health -= int(damage)
			hit_enemy.emit(other, damage)
			
		time_since_last_hit = 0.0
