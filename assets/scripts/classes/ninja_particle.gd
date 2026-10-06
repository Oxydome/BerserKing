class_name NinjaParticle
extends Area2D

## Particle collision damage triggers and orientation flipping ported from Unity Ninja_Particle.cs.
## Replicates:
##   - OnParticleCollision(GameObject other): en.TakeDamage(damage)
##   - FlipYRotation(): flips particle system local Y orientation (horizontal flip in 2D)

signal hit_enemy(enemy: Node, damage_dealt: float)
signal flipped(facing_flipped: bool)

@export var damage : float = 10.0
@export var particle_system : Node # Reference to CPUParticles2D, GPUParticles2D, or Sprite

var is_flipped_y : bool = false

# Uppercase aliases matching Unity C# naming convention
var Damage : float:
	get: return damage
	set(val): damage = val
var ParticleSystemRef : Node:
	get: return particle_system
	set(val): particle_system = val

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if particle_system == null:
		particle_system = get_node_or_null("CPUParticles2D")
		if particle_system == null:
			particle_system = get_node_or_null("GPUParticles2D")

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
	if other == null:
		return
	if other.has_method("TakeDamage"):
		other.TakeDamage(damage)
		hit_enemy.emit(other, damage)
	elif other.has_method("take_damage"):
		other.take_damage(damage)
		hit_enemy.emit(other, damage)
	elif "health" in other:
		other.health -= int(damage)
		hit_enemy.emit(other, damage)

## Unity FlipYRotation() logic: inverts local orientation
func FlipYRotation() -> void:
	flip_y_rotation()

func flip_y_rotation() -> void:
	is_flipped_y = not is_flipped_y
	if particle_system != null:
		if particle_system is Node2D:
			particle_system.scale.x *= -1.0
		elif "flip_h" in particle_system:
			particle_system.flip_h = not particle_system.flip_h
	else:
		scale.x *= -1.0
	flipped.emit(is_flipped_y)
