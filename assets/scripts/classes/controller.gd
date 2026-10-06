extends Node

class_name Controller
@export var speed : int

func _init(speed := 100) -> void:
	self.speed = speed
	
func _process(_delta: float) -> void:
	var parent = get_parent()
	if Global.CurrentPlayer != null:
		parent.velocity = (Global.CurrentPlayer.position - parent.position).normalized() * self.speed
	parent.move_and_slide()
	self.collision(parent)
	
func collision(parent):
	var last_collision = parent.get_last_slide_collision()
	if last_collision != null:
		Global.controller_touch.emit(parent, last_collision.get_collider() as Entity)
