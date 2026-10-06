class_name Attribute
extends ItemResource

## Attribute ScriptableObject port from Unity Attribute.cs.
## Contains multi-level stat modifications targeting components via dynamic reflection.

class IState extends Resource:
	@export var component_name : String = ""
	@export var stat_name : String = ""
	@export var value : Variant = ""
	@export var overwrite : bool = false
	
	# Uppercase aliases matching Unity C# Attribute.IState
	var ComponentName : String:
		get: return component_name
		set(val): component_name = val
	var StatName : String:
		get: return stat_name
		set(val): stat_name = val
	var Value : Variant:
		get: return value
		set(val): value = val
	var OverWrite : bool:
		get: return overwrite
		set(val): overwrite = val

	func _init(comp: String = "", stat: String = "", val: Variant = "", ow: bool = false) -> void:
		component_name = comp
		stat_name = stat
		value = val
		overwrite = ow

class State extends IState:
	pass

class Level extends Resource:
	@export var description : String = ""
	@export var states : Array = [] # Untyped to allow flexible array assignment
	
	# Uppercase aliases matching Unity C# Attribute.Level
	var Description : String:
		get: return description
		set(val): description = val
	var States : Array:
		get: return states
		set(val): states = val

	func _init(desc: String = "", p_states: Array = []) -> void:
		description = desc
		states = p_states

@export var levels : Array = [] # Untyped to allow flexible array assignment

var Levels : Array:
	get: return levels
	set(val): levels = val
