extends CharacterBody2D

class_name GameObject
@export var data : GameObjectResource
@export var sprite_anim : AnimatedSprite2D
@export var collision_shape : CollisionShape2D

func _init(data : GameObjectResource, do_spawning := true) -> void:
	self.data = data
	if do_spawning: spawn()
	
func spawn() -> void:
	name = data.name
	self.sprite_anim = AnimatedSprite2D.new()
	self.sprite_anim.sprite_frames = data.sprite_frames
	add_child(self.sprite_anim)
	self.collision_shape = CollisionShape2D.new()
	self.collision_shape.shape = data.shape
	if data.shape is CircleShape2D:
		self.collision_shape.shape.radius = float(data.sprite_frames.get_frame_texture(data.sprite_frames.get_animation_names()[0], 0).get_width()) / 2.0
	elif data.shape is RectangleShape2D:
		self.collision_shape.shape.size = Vector2(data.sprite_frames.get_frame_texture(data.sprite_frames.get_animation_names()[0], 0).get_size()) / 2.0
	elif data.shape is CapsuleShape2D:
		self.collision_shape.shape.radius = float(data.sprite_frames.get_frame_texture(data.sprite_frames.get_animation_names()[0], 0).get_width()) / 2.0
		self.collision_shape.shape.height = float(data.sprite_frames.get_frame_texture(data.sprite_frames.get_animation_names()[0], 0).get_height()) / 2.0
	add_child(self.collision_shape)
	Global.object_spawned.emit(data)

func despawn() -> void:
	queue_free()
	Global.object_despawned.emit(data)
