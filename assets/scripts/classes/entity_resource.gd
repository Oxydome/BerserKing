extends GameObjectResource

class_name EntityResource

## ScriptableObject-based entity configuration ported from Unity Entity.cs.
## Replicates:
##   public int ID;
##   public string Name;
##   public string Description;
##   public int Health;
##   public int MaxHealth;
##   public float Speed;
##   public float MaxSpeed;
##   public AnimatorController EntityAnimator;

@export var id : int = 0
@export var description : String = ""
@export var damage : int = 2
@export var health : int = 30
@export var max_health : int = 30
@export var speed : float = 100.0
@export var max_speed : float = 200.0
## Per second
@export var health_regenerate : int = 0 
@export var scene : PackedScene

# Uppercase aliases matching Unity C# naming convention
var ID : int:
	get: return id
	set(val): id = val

var Name : String:
	get: return name
	set(val): name = val

var Description : String:
	get: return description
	set(val): description = val

@warning_ignore("shadowed_global_identifier")
var Damage : int:
	get: return damage
	set(val): damage = val

@warning_ignore("shadowed_global_identifier")
var Health : int:
	get: return health
	set(val): health = val

var MaxHealth : int:
	get: return max_health
	set(val): max_health = val

var Speed : float:
	get: return speed
	set(val): speed = val

var MaxSpeed : float:
	get: return max_speed
	set(val): max_speed = val

var EntityAnimator : SpriteFrames:
	get: return sprite_frames
	set(val): sprite_frames = val

func _init(p_name : String = "", p_health : int = 0, p_max_health : int = 0, p_health_regenerate : int = 0, p_damage : int = 0, p_sprite_frames : SpriteFrames = null, p_shape : Shape2D = null) -> void:
	super._init(p_name, p_sprite_frames, p_shape)
	self.damage = p_damage
	self.health = p_health
	self.max_health = p_max_health
	self.health_regenerate = p_health_regenerate
