class_name Movement
extends Node

## Movement and Dash System ported from Unity Movement.cs.
## Controls 8-directional physics movement, directional flipping,
## and coroutine-driven dashing with TrailRenderer and gravity toggling.

signal dashed
signal dash_finished
signal flipped(facing_right: bool)

@export_group("Movement")
@export var speed : float = 400.0
@export var drag : float = 0.5
@export var gravity_scale : float = 0.0

@export_group("Dash")
@export var dashing_power : float = 900.0
@export var dashing_time : float = 0.75
@export var dashing_cooldown : float = 1.0

@export_group("References")
@export var body_path : NodePath
@export var animator_path : NodePath
@export var trail_renderer_path : NodePath

# Runtime state variables matching Unity Movement.cs
var horizontal_move : float = 0.0
var vertical_move : float = 0.0
var is_facing_right : bool = true
var can_dash : bool = true
var is_dashing : bool = false

# Uppercase property aliases matching Unity C# naming convention
var Speed : float:
	get: return speed
	set(val): speed = val
var HorizontalMove : float:
	get: return horizontal_move
	set(val): horizontal_move = val
var VerticalMove : float:
	get: return vertical_move
	set(val): vertical_move = val
var IsFacingRight : bool:
	get: return is_facing_right
	set(val): is_facing_right = val
var CanDash : bool:
	get: return can_dash
	set(val): can_dash = val
var IsDashing : bool:
	get: return is_dashing
	set(val): is_dashing = val
var DashingPower : float:
	get: return dashing_power
	set(val): dashing_power = val
var DashingTime : float:
	get: return dashing_time
	set(val): dashing_time = val
var DashingCooldown : float:
	get: return dashing_cooldown
	set(val): dashing_cooldown = val

var body : CharacterBody2D
var animator : AnimatedSprite2D
var trail_renderer : Line2D

func _ready() -> void:
	if body_path and has_node(body_path):
		body = get_node(body_path) as CharacterBody2D
	elif get_parent() is CharacterBody2D:
		body = get_parent() as CharacterBody2D
		
	if animator_path and has_node(animator_path):
		animator = get_node(animator_path) as AnimatedSprite2D
	elif body != null and body.has_node("AnimatedSprite2D"):
		animator = body.get_node("AnimatedSprite2D") as AnimatedSprite2D
		
	if trail_renderer_path and has_node(trail_renderer_path):
		trail_renderer = get_node(trail_renderer_path) as Line2D
	elif body != null and body.has_node("TrailRenderer"):
		trail_renderer = body.get_node("TrailRenderer") as Line2D

func _process(delta: float) -> void:
	Update(delta)

## Unity-style Update: checks input and initiates dash
func Update(_delta: float = 0.0) -> void:
	Flip()
	if is_dashing:
		return
		
	if (Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("roll") or Input.is_key_pressed(KEY_SPACE)) and can_dash:
		Dash()

func _physics_process(delta: float) -> void:
	FixedUpdate(delta)

## Unity-style FixedUpdate: handles 8-directional physics movement and dash velocity
func FixedUpdate(delta: float = 0.0) -> void:
	if body == null:
		return
		
	if is_dashing:
		if body.is_inside_tree():
			body.move_and_slide()
		return
		
	horizontal_move = Input.get_axis("move_left", "move_right")
	vertical_move = Input.get_axis("move_up", "move_down")
	
	var input_vector = Vector2(horizontal_move, vertical_move)
	if input_vector.length() > 0.0:
		body.velocity = input_vector.normalized() * speed
		if animator != null and animator.sprite_frames != null and animator.sprite_frames.has_animation("run") and (animator.animation != "run" or not animator.is_playing()):
			animator.play("run")
	else:
		body.velocity = body.velocity * drag
		if animator != null and animator.sprite_frames != null and animator.sprite_frames.has_animation("idle") and (animator.animation != "idle" or not animator.is_playing()):
			animator.play("idle")
			
	if gravity_scale != 0.0:
		body.velocity.y += gravity_scale * 980.0 * delta
		
	if body.is_inside_tree():
		body.move_and_slide()

## Unity-style Flip: flips orientation when changing horizontal direction
func Flip() -> void:
	if (is_facing_right and horizontal_move < 0.0) or (not is_facing_right and horizontal_move > 0.0):
		is_facing_right = not is_facing_right
		if animator != null:
			animator.flip_h = not is_facing_right
		flipped.emit(is_facing_right)

## Unity-style Dash: coroutine-driven dash with gravity toggling and TrailRenderer
func Dash() -> void:
	dash()

func dash() -> void:
	if not can_dash or is_dashing:
		return
		
	can_dash = false
	is_dashing = true
	dashed.emit()
	
	var original_gravity = gravity_scale
	gravity_scale = 0.0
	
	var facing_direction = 1.0 if is_facing_right else -1.0
	if body != null:
		body.velocity = Vector2(facing_direction * dashing_power, 0.0)
		
	if animator != null:
		if animator.sprite_frames != null and animator.sprite_frames.has_animation("roll"):
			animator.play("roll")
		elif animator.sprite_frames != null and animator.sprite_frames.has_animation("dash"):
			animator.play("dash")
			
	if trail_renderer != null and "emitting" in trail_renderer:
		trail_renderer.emitting = true
		
	var tree : SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		await tree.create_timer(dashing_time).timeout
		
	if trail_renderer != null and "emitting" in trail_renderer:
		trail_renderer.emitting = false
		
	if animator != null and animator.animation in ["roll", "dash"] and animator.sprite_frames != null and animator.sprite_frames.has_animation("idle"):
		animator.play("idle")
		
	gravity_scale = original_gravity
	is_dashing = false
	dash_finished.emit()
	
	if tree != null:
		await tree.create_timer(dashing_cooldown).timeout
	can_dash = true
