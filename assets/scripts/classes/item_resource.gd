extends GameObjectResource

class_name ItemResource

## Item ScriptableObject port from Unity Item.cs.
## Extends GameObjectResource to retain 100% backwards compatibility with Godot version.

@export var id : int = 0
@export var item_name : String = ""
@export var item_description : String = ""
@export var item_sprite : Texture2D
@export var play_on_pick_up : AudioStream
@export var spawn_rate : float = 0.5

# Uppercase aliases matching Unity C# Item.cs naming conventions
var ID : int:
	get: return id
	set(val): id = val

var ItemName : String:
	get:
		if item_name != "":
			return item_name
		return name
	set(val):
		item_name = val
		name = val

var ItemDescription : String:
	get: return item_description
	set(val): item_description = val

var ItemSprite : Texture2D:
	get:
		if item_sprite != null:
			return item_sprite
		if sprite_frames != null and sprite_frames.has_animation("default"):
			if sprite_frames.get_frame_count("default") > 0:
				return sprite_frames.get_frame_texture("default", 0)
		return null
	set(val): item_sprite = val

var PlayOnPickUp : AudioStream:
	get: return play_on_pick_up
	set(val): play_on_pick_up = val

var SpawnRate : float:
	get: return spawn_rate
	set(val): spawn_rate = val

func _init(p_name: String = "", p_sprite_frames: SpriteFrames = null, p_shape: Shape2D = null) -> void:
	super._init(p_name, p_sprite_frames, p_shape)
	if p_name != "":
		self.item_name = p_name
