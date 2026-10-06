extends Node
class_name Health

@export var health : int
@export var max_health : int
@export var health_regenerate : int
@export var slider : Range # Reference to TextureProgressBar or ProgressBar slider

var cooldown : Timer = Timer.new()

# Uppercase aliases matching Unity C# Health.cs
var Health : int:
	get: return health
	set(val): health = val
var MaxHealth : int:
	get: return max_health
	set(val): max_health = val
var slider_bar : Range:
	get: return slider
	set(val): slider = val

func get_slider() -> Range:
	return slider

func set_slider(val: Range) -> void:
	slider = val

func SetMaxHealth(p_health: int) -> void:
	set_max_health(p_health)

func set_max_health(p_health: int) -> void:
	max_health = p_health
	health = p_health
	if slider != null:
		slider.max_value = p_health
		slider.value = p_health

func SetHealth(p_health: int) -> void:
	set_health(p_health)

func set_health(p_health: int) -> void:
	health = p_health
	if slider != null:
		slider.value = p_health

func take_damage(damage : int):
	print(get_parent().name + " took " +str(damage)+ " damage")
	health-=damage
	if slider != null:
		slider.value = health
	var global = get_node_or_null("/root/Global")
	if global != null and global.has_signal("health_took_damage"):
		global.health_took_damage.emit(self)
	if health <= 0:
		if global != null and global.has_signal("health_killed"):
			global.health_killed.emit(get_parent())
	
func _init(p_max_health : int = 100, p_health : int = 100, p_health_regenerate : int = 0):
	cooldown.one_shot = true
	add_child(cooldown)
	self.health = p_health
	self.max_health = p_max_health
	self.health_regenerate = p_health_regenerate
	#savienot no global.gd controller 
	var global = (Engine.get_main_loop() as SceneTree).root.get_node_or_null("Global") if Engine.get_main_loop() is SceneTree else null
	if global != null and global.has_signal("controller_touch"):
		global.controller_touch.connect(on_touch)
	
func on_touch(entity : Entity, other : Entity):
	if cooldown.time_left != 0:
		return
	if entity == get_parent():
		take_damage(other.damage)
		cooldown.start(0.1)

func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	await get_tree().create_timer(1).timeout
	if health+health_regenerate < max_health:
		health+=health_regenerate
		if slider != null:
			slider.value = health
