extends Resource

class_name GameObjectResource

@export var name : String
@export var sprite_frames : SpriteFrames
@export var shape : Shape2D
	
func _init(p_name : String = "", p_sprite_frames : SpriteFrames = null, p_shape : Shape2D = null) -> void:
	self.name = p_name
	self.sprite_frames = p_sprite_frames
	self.shape = p_shape
