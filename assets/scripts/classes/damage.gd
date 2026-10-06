class_name Damage
extends Node

## Contact damage cooldown and player health system ported from Unity Damage.cs.
## Replicates:
##   public int damageperframe = 20;
##   public int playerHealth;
##   public int maxHealth = 100;
##   public Health health;
##   async void DoDamage(Collision2D enemy) { ... playerHealth -= damageperframe; await Task.Delay(500); cooldown = false; health.SetHealth(playerHealth); }
##   private void OnCollisionStay2D(UnityEngine.Collision2D collision) { if (!cooldown) { cooldown = true; DoDamage(collision); } }

signal health_changed(current_health: int, max_health: int)
signal damage_taken(amount: int, source: Node)
signal player_died()

@export var damageperframe : int = 20
@export var max_health : int = 100
@export var player_health : int = 100
@export var cooldown_time : float = 0.5
@export var enemy_name_filter : String = ""

# Uppercase aliases matching Unity C# naming convention
var DamagePerFrame : int:
	get: return damageperframe
	set(val): damageperframe = val
var PlayerHealth : int:
	get: return player_health
	set(val): player_health = val
var MaxHealth : int:
	get: return max_health
	set(val): max_health = val

@export var health : Node:
	get:
		if _health_ref == null:
			_resolve_health_bar()
		return _health_ref
	set(val):
		_health_ref = val
var _health_ref : Node = null

var HealthComponent : Node:
	get: return health
	set(val): health = val

var cooldown : bool = false
var Cooldown : bool:
	get: return cooldown
	set(val): cooldown = val

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _ready() -> void:
	Start()

func Start() -> void:
	player_health = max_health
	_resolve_health_bar()
				
	if health != null:
		if health.has_method("SetMaxHealth"):
			health.SetMaxHealth(max_health)
		elif health.has_method("set_max_health"):
			health.set_max_health(max_health)
		_update_ui_health(player_health)
			
	health_changed.emit(player_health, max_health)

func _resolve_health_bar() -> void:
	if _health_ref != null:
		return
	var global = _get_global()
	if global != null and global.CurrentGameUI != null:
		_health_ref = global.CurrentGameUI.find_child("HealthBar", true, false)
	if _health_ref == null and get_parent() != null:
		var parent_health = get_parent().get_node_or_null("Health")
		if parent_health != null:
			_health_ref = parent_health
	if _health_ref == null and is_inside_tree():
		_health_ref = get_tree().root.find_child("HealthBar", true, false)

func _update_ui_health(hp: int) -> void:
	_resolve_health_bar()
	if _health_ref != null:
		if _health_ref.has_method("SetHealth"):
			_health_ref.SetHealth(hp)
		elif _health_ref.has_method("set_health"):
			_health_ref.set_health(hp)

func take_damage(amount: int) -> void:
	if cooldown:
		return
	cooldown = true
	player_health = clampi(player_health - amount, 0, max_health)
	
	var parent_node = get_parent()
	if parent_node != null and "health" in parent_node:
		parent_node.health = player_health
		
	damage_taken.emit(amount, null)
	health_changed.emit(player_health, max_health)
	_update_ui_health(player_health)
	
	if parent_node != null and parent_node.has_node("AnimatedSprite2D"):
		var anim = parent_node.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("get_hit"):
			anim.play("get_hit")
			
	if player_health <= 0:
		player_died.emit()
		if parent_node != null and parent_node.has_method("die"):
			parent_node.die()
		return
		
	var tree : SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		await tree.create_timer(cooldown_time).timeout
	cooldown = false

## Unity async void DoDamage(Collision2D enemy) pipeline
func DoDamage(enemy: Variant) -> void:
	if cooldown:
		return
	cooldown = true
	var enemy_node : Node = null
	if enemy is Node:
		enemy_node = enemy
	elif enemy is KinematicCollision2D:
		enemy_node = enemy.get_collider()
		
	if enemy_node == null:
		cooldown = false
		return
		
	# Ignore environment tilemaps and static boundaries: walls never deal contact damage to player
	if enemy_node is TileMap or enemy_node is TileMapLayer:
		cooldown = false
		return
	if enemy_node is StaticBody2D and not (enemy_node.is_in_group("enemy") or enemy_node.is_in_group("enemies")):
		cooldown = false
		return
		
	var parent_node = get_parent()
	var enemy_name : String = str(enemy_node.name) if enemy_node != null else ""
	
	# Determine if enemy is a valid hostile target
	var is_hostile : bool = false
	if enemy_node.is_in_group("enemy") or enemy_node.is_in_group("enemies"):
		is_hostile = true
	elif enemy_name_filter != "":
		is_hostile = (enemy_name.findn(enemy_name_filter) != -1 or enemy_node.is_in_group(enemy_name_filter))
	elif "touch_damage" in enemy_node or "damage" in enemy_node or enemy_node.has_meta("is_enemy"):
		is_hostile = true
	elif enemy_node.has_method("take_damage") or enemy_node.has_method("TakeDamage"):
		is_hostile = true
		
	if not is_hostile:
		cooldown = false
		return
			
	var dmg = damageperframe
	if enemy_node != null:
		if "damage" in enemy_node and int(enemy_node.damage) > 0:
			dmg = maxi(damageperframe, int(enemy_node.damage))
		elif enemy_node.has_meta("damage") and int(enemy_node.get_meta("damage")) > 0:
			dmg = maxi(damageperframe, int(enemy_node.get_meta("damage")))

	player_health = clampi(player_health - dmg, 0, max_health)
	damage_taken.emit(dmg, enemy_node)
	health_changed.emit(player_health, max_health)
	
	# Keep parent entity's health variable in sync if present
	if parent_node != null and "health" in parent_node:
		parent_node.health = player_health
		
	# Play hit animation on parent if available
	if parent_node != null and parent_node.has_node("AnimatedSprite2D"):
		var anim = parent_node.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if anim != null and anim.sprite_frames != null and anim.sprite_frames.has_animation("get_hit"):
			anim.play("get_hit")
			
	# Update UI health bar IMMEDIATELY!
	_update_ui_health(player_health)

	if player_health <= 0:
		player_died.emit()
		if parent_node != null and parent_node.has_method("die"):
			parent_node.die()
		return
			
	# Asynchronous cooldown pipeline: await Task.Delay(500)
	var tree : SceneTree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	if tree != null:
		await tree.create_timer(cooldown_time).timeout
	cooldown = false

## Unity OnCollisionStay2D callback
func OnCollisionStay2D(collision: Variant) -> void:
	if not cooldown:
		DoDamage(collision)
