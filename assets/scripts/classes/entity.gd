extends GameObject

class_name Entity
@export var controller : Controller
@export var health : Health
@export var damage : int

func _init(data : EntityResource, do_spawning := true) -> void:
	super._init(data as GameObjectResource, do_spawning)
	self.damage = data.damage
	self.controller = Controller.new()
	self.health = Health.new(data.max_health, data.health)
	add_child(self.controller)
	add_child(self.health)
	if Global != null and Global.has_signal("health_killed"):
		Global.health_killed.connect(_on_global_health_killed)

func _on_global_health_killed(killed_entity: Node) -> void:
	if killed_entity == self:
		despawn()
