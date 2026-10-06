extends CharacterBody2D

## Player Movement & Dash System ported from Unity Movement.cs & Player.prefab.
## Features 8-directional physics movement, directional flipping, and a coroutine-driven
## dash mechanic utilizing gravity toggling, horizontal velocity bursts, and TrailRenderer.

signal dashed
signal dash_finished
signal flipped(facing_right: bool)
signal health_changed(current_health: int, max_health: int)

@export_group("Movement")
@export var speed : float = 400.0
@export var drag : float = 0.5
@export var gravity_scale : float = 0.0

@export_group("Dash")
@export var dashing_power : float = 900.0
@export var dashing_time : float = 0.75
@export var dashing_cooldown : float = 1.0

@export_group("Combat & Stats")
@export var health : int = 100
@export var max_health : int = 100
@export var regen_every_second : int = 0
@export var touch_damage : int = 10

# Compatibility constants/properties from original Godot player.gd
var roll_speed : float:
	get: return dashing_power
	set(val): dashing_power = val
var roll_time : float:
	get: return dashing_time
	set(val): dashing_time = val
var roll_cooldown : float:
	get: return dashing_cooldown
	set(val): dashing_cooldown = val
var regen : int:
	get: return regen_every_second
	set(val): regen_every_second = val

# Uppercase aliases matching Unity C# naming convention
var Speed : float:
	get: return speed
	set(val): speed = val
var Drag : float:
	get: return drag
	set(val): drag = val
var GravityScale : float:
	get: return gravity_scale
	set(val): gravity_scale = val
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
var HealthStat : int:
	get: return health
	set(val): health = val
var MaxHealthStat : int:
	get: return max_health
	set(val): max_health = val

# Contact Damage Cooldown System ported from Unity Damage.cs
var _damage_system : Damage
var damage_system : Damage:
	get:
		if _damage_system == null and is_instance_valid(self):
			_damage_system = get_node_or_null("Damage") as Damage
			if _damage_system == null:
				_damage_system = Damage.new()
				_damage_system.name = "Damage"
				_damage_system.max_health = max_health
				_damage_system.player_health = health
				add_child(_damage_system)
		return _damage_system
	set(val): _damage_system = val

var DamageSystem : Damage:
	get: return damage_system
	set(val): damage_system = val

# Node references with lazy fallback getters and backwards compatibility aliases
var _animator : AnimatedSprite2D
var animator : AnimatedSprite2D:
	get:
		if _animator == null and is_instance_valid(self):
			_animator = get_node_or_null("AnimatedSprite2D")
		return _animator
	set(val): _animator = val

var an : AnimatedSprite2D:
	get: return animator
	set(val): animator = val

var animation : AnimatedSprite2D:
	get: return animator
	set(val): animator = val

var _trail_renderer : Line2D
var trail_renderer : Line2D:
	get:
		if _trail_renderer == null and is_instance_valid(self):
			_trail_renderer = get_node_or_null("TrailRenderer")
		return _trail_renderer
	set(val): _trail_renderer = val

@warning_ignore("shadowed_variable_base_class")
var tr : Line2D:
	get: return trail_renderer
	set(val): trail_renderer = val

var _roll : Node
var roll : Node:
	get:
		if _roll == null and is_instance_valid(self):
			_roll = get_node_or_null("Roll")
		return _roll
	set(val): _roll = val

var horizontal_move : float = 0.0
var vertical_move : float = 0.0
var is_facing_right : bool = true
var can_dash : bool = true
var is_dashing : bool = false

func _ready() -> void:
	add_to_group("player")
	var global = get_node_or_null("/root/Global")
	if global != null:
		global.CurrentPlayer = self
	_animator = get_node_or_null("AnimatedSprite2D")
	_trail_renderer = get_node_or_null("TrailRenderer")
	_roll = get_node_or_null("Roll")
	
	# Apply selected character sprite frames
	if animator != null:
		var char_path = ""
		if global != null and "CurrentCharacterPath" in global and global.CurrentCharacterPath != "":
			char_path = global.CurrentCharacterPath
		if char_path != "" and ResourceLoader.exists(char_path):
			var sf = load(char_path)
			if sf is SpriteFrames:
				animator.sprite_frames = sf
		
		# Adjust offset based on character sprite dimensions
		if animator.sprite_frames != null:
			var res_path = animator.sprite_frames.resource_path
			if res_path.contains("player_c"):
				animator.position = Vector2(0, -18)
				animator.scale = Vector2(1.5, 1.5)
			elif res_path.contains("bandit"):
				animator.position = Vector2(0, -14)
				animator.scale = Vector2(1.5, 1.5)
			else:
				animator.position = Vector2(0, -44)
				animator.scale = Vector2(1.0, 1.0)
				
			if animator.sprite_frames.has_animation("idle"):
				animator.play("idle")
	
	# Initialize Damage component
	if not has_node("Damage"):
		_damage_system = Damage.new()
		_damage_system.name = "Damage"
		_damage_system.max_health = max_health
		_damage_system.player_health = health
		add_child(_damage_system)
	else:
		_damage_system = get_node("Damage") as Damage

	# Ensure player starts with ninja stars (shuriken) weapon
	if not has_node("Shuriken") and ResourceLoader.exists("res://assets/scripts/objects/weapons/shuriken/shuriken.tscn"):
		var shuriken_res = load("res://assets/scripts/objects/weapons/shuriken/shuriken.tscn")
		if shuriken_res is PackedScene:
			var shuriken_node = shuriken_res.instantiate()
			shuriken_node.name = "Shuriken"
			add_child(shuriken_node)

	# Periodic health regeneration timer (only active if regen_every_second > 0)
	if regen_every_second > 0:
		var regen_timer = Timer.new()
		regen_timer.name = "RegenTimer"
		regen_timer.wait_time = 1.0
		regen_timer.autostart = true
		regen_timer.timeout.connect(_on_regen_timeout)
		add_child(regen_timer)
		
	call_deferred("_init_health_bar")

func _init_health_bar() -> void:
	var bar = _get_health_bar_node()
	if bar != null:
		if bar.has_method("set_max_health"):
			bar.set_max_health(max_health)
		elif bar.has_method("SetMaxHealth"):
			bar.SetMaxHealth(max_health)
		if bar.has_method("set_health"):
			bar.set_health(health)
		elif bar.has_method("SetHealth"):
			bar.SetHealth(health)
		if damage_system != null:
			damage_system.health = bar

func _get_health_bar_node() -> Node:
	var global = get_node_or_null("/root/Global")
	if global != null and global.CurrentGameUI != null:
		var bar = global.CurrentGameUI.find_child("HealthBar", true, false)
		if bar != null:
			return bar
	if is_inside_tree():
		var bar = get_tree().root.find_child("HealthBar", true, false)
		if bar != null:
			return bar
	return null

func _update_health_bar(hp: int = -1) -> void:
	var current_hp = hp if hp >= 0 else health
	var bar = _get_health_bar_node()
	if bar != null:
		if bar.has_method("set_health"):
			bar.set_health(current_hp)
		elif bar.has_method("SetHealth"):
			bar.SetHealth(current_hp)

## Unity-style Update: handles directional flip check and dash trigger
func _process(delta: float) -> void:
	Update(delta)

func Update(_delta: float = 0.0) -> void:
	Flip()
	if is_dashing:
		return
		
	if (Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("roll") or Input.is_key_pressed(KEY_SPACE)) and can_dash:
		Dash()

## Unity-style FixedUpdate: handles 8-directional physics movement and dash translation
func _physics_process(delta: float) -> void:
	FixedUpdate(delta)

func FixedUpdate(delta: float = 0.0) -> void:
	if is_dashing:
		if is_inside_tree():
			move_and_slide()
			_handle_slide_collisions()
		return
		
	# 8-directional physics movement input
	horizontal_move = Input.get_axis("move_left", "move_right")
	vertical_move = Input.get_axis("move_up", "move_down")
	
	var input_vector = Vector2(horizontal_move, vertical_move)
	if input_vector.length() > 0.0:
		velocity = input_vector.normalized() * speed
		if animator != null and animator.sprite_frames != null:
			var move_anim = "walk" if animator.sprite_frames.has_animation("walk") else ("run" if animator.sprite_frames.has_animation("run") else "")
			if move_anim != "" and (animator.animation != move_anim or not animator.is_playing()):
				animator.play(move_anim)
	else:
		velocity = velocity * drag
		if animator != null and animator.sprite_frames != null and animator.sprite_frames.has_animation("idle") and (animator.animation != "idle" or not animator.is_playing()):
			animator.play("idle")
			
	if gravity_scale != 0.0:
		velocity.y += gravity_scale * 980.0 * delta
		
	if is_inside_tree():
		move_and_slide()
		_handle_slide_collisions()

## Unity-style Flip(): flips sprite orientation based on horizontal movement
func Flip() -> void:
	flip()

func flip() -> void:
	if (is_facing_right and horizontal_move < 0.0) or (not is_facing_right and horizontal_move > 0.0):
		is_facing_right = not is_facing_right
		if animator != null:
			animator.flip_h = not is_facing_right
		emit_signal("flipped", is_facing_right)

## Unity-style Dash Coroutine (IEnumerator Dash()) ported via SceneTreeTimer
func Dash() -> void:
	dash()

func dash() -> void:
	if not can_dash or is_dashing:
		return
		
	can_dash = false
	is_dashing = true
	emit_signal("dashed")
	
	# Determine dash direction vector based on current input or facing
	var dash_dir = Vector2(horizontal_move, vertical_move)
	if dash_dir.length_squared() == 0.0:
		dash_dir = Vector2.RIGHT if is_facing_right else Vector2.LEFT
	else:
		dash_dir = dash_dir.normalized()
		
	velocity = dash_dir * dashing_power
	
	if trail_renderer != null:
		trail_renderer.emitting = true
	if animator != null and animator.sprite_frames != null and animator.sprite_frames.has_animation("roll"):
		animator.play("roll")
		
	# dashing_time duration
	var timer = get_tree().create_timer(dashing_time)
	timer.timeout.connect(_on_dash_time_completed)

func _on_dash_time_completed() -> void:
	if trail_renderer != null:
		trail_renderer.emitting = false
	is_dashing = false
	emit_signal("dash_finished")
	
	# dashing_cooldown duration
	var timer = get_tree().create_timer(dashing_cooldown)
	timer.timeout.connect(_on_dash_cooldown_completed)

func _on_dash_cooldown_completed() -> void:
	can_dash = true

## Handles slide collision interactions (e.g. damaging touch on enemies)
func _handle_slide_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider != null and (collider.is_in_group("enemies") or collider.is_in_group("enemy")):
			if is_dashing:
				if collider.has_method("take_damage"):
					collider.take_damage(touch_damage)
				elif collider.has_signal("health_damaged"):
					collider.emit_signal("health_damaged", touch_damage)
			else:
				# Contact damage received from enemy
				DoDamage(collider)
				# If touch damage is active, deal touch damage with 0.5s cooldown so enemies aren't instantly deleted
				if touch_damage > 0 and collider.has_method("take_damage"):
					if not collider.has_meta("_touch_cd"):
						collider.set_meta("_touch_cd", true)
						collider.take_damage(touch_damage)
						var col_id = collider.get_instance_id()
						var t = get_tree().create_timer(0.5)
						t.timeout.connect(_clear_touch_cd.bind(col_id))

func _clear_touch_cd(target_id: int) -> void:
	var target = instance_from_id(target_id)
	if is_instance_valid(target) and target.has_meta("_touch_cd"):
		target.remove_meta("_touch_cd")

func _on_regen_timeout() -> void:
	if regen_every_second <= 0:
		return
	if health < max_health:
		health = mini(health + regen_every_second, max_health)
		if damage_system != null:
			damage_system.player_health = health
		_update_health_bar(health)
		health_changed.emit(health, max_health)

## Unity-style DoDamage callback: handles incoming damage from enemy with cooldown
func DoDamage(enemy_node: Variant) -> void:
	if is_dashing:
		return
	if damage_system != null:
		damage_system.DoDamage(enemy_node)
		health = damage_system.player_health
	else:
		var dmg = 20
		if enemy_node != null:
			if "damage" in enemy_node and int(enemy_node.damage) > 0:
				dmg = maxi(20, int(enemy_node.damage))
			elif enemy_node.has_meta("damage") and int(enemy_node.get_meta("damage")) > 0:
				dmg = maxi(20, int(enemy_node.get_meta("damage")))
		take_damage(dmg)

func take_damage(amount: int) -> void:
	if is_dashing:
		return
	if damage_system != null:
		damage_system.take_damage(amount)
		health = damage_system.player_health
	else:
		health = clampi(health - amount, 0, max_health)
		_update_health_bar(health)
		health_changed.emit(health, max_health)
		if animator != null and animator.sprite_frames != null and animator.sprite_frames.has_animation("get_hit"):
			animator.play("get_hit")
		if health <= 0:
			die()

func die() -> void:
	if animator != null and animator.sprite_frames != null and animator.sprite_frames.has_animation("death"):
		animator.play("death")
	# Transition to game over menu
	var global = get_node_or_null("/root/Global")
	if global != null and global.has_method("change_scene"):
		global.change_scene("res://assets/scripts/globals/default_transition.tscn", "res://assets/objects/menus/game_over.tscn", "fade_center")
	else:
		get_tree().change_scene_to_file("res://assets/objects/menus/game_over.tscn")
