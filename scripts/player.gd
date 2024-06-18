extends CharacterBody2D

@export var speed := 150.0
@export var drag := 0.4

func _physics_process(delta):
	var direction = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))
	velocity = velocity * drag if direction == Vector2.ZERO else direction * speed
	move_and_slide()
