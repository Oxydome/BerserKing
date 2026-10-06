class_name FollowPath
extends Node2D

## Spline path progression for orbiting weapons ported from Unity FollowPath.cs.
## Replicates:
##   distanceTravelled += speed * Time.deltaTime;
##   transform.position = pathCreator.path.GetPointAtDistance(distanceTravelled);

@export var path_creator : Node
@export var speed : float = 150.0
@export var auto_rotate : bool = true

var distance_travelled : float = 0.0

# Uppercase and alternative aliases matching Unity C# naming convention
var pathCreator : Node:
	get: return path_creator
	set(val): path_creator = val

var PathCreatorNode : Node:
	get: return path_creator
	set(val): path_creator = val

var Speed : float:
	get: return speed
	set(val): speed = val

var distanceTravelled : float:
	get: return distance_travelled
	set(val): distance_travelled = val

var DistanceTravelled : float:
	get: return distance_travelled
	set(val): distance_travelled = val

func _ready() -> void:
	if path_creator == null:
		# Check if parent or sibling is a PathCreator or Path2D
		if get_parent() != null and (get_parent().has_method("GetPointAtDistance") or "path" in get_parent()):
			path_creator = get_parent()
		elif get_parent() != null and get_parent().has_node("PathCreator"):
			path_creator = get_parent().get_node("PathCreator")

func _process(delta: float) -> void:
	Update(delta)

## Unity Update() logic
func Update(delta: float = 0.0) -> void:
	if path_creator == null:
		return
		
	distance_travelled += speed * delta
	
	var target_local_pos = Vector2.ZERO
	
	if "path" in path_creator and path_creator.path != null and path_creator.path.has_method("GetPointAtDistance"):
		target_local_pos = path_creator.path.GetPointAtDistance(distance_travelled)
	elif path_creator.has_method("GetPointAtDistance"):
		target_local_pos = path_creator.GetPointAtDistance(distance_travelled)
	elif "curve" in path_creator and path_creator.curve != null:
		var baked_len = path_creator.curve.get_baked_length()
		var dist = fposmod(distance_travelled, baked_len) if baked_len > 0.0 else 0.0
		target_local_pos = path_creator.curve.sample_baked(dist)
	elif path_creator is PathFollow2D:
		path_creator.progress = distance_travelled
		target_local_pos = path_creator.position
		
	if get_parent() == path_creator:
		position = target_local_pos
	else:
		global_position = path_creator.global_position + target_local_pos
		
	if auto_rotate:
		var next_pos = Vector2.ZERO
		if "path" in path_creator and path_creator.path != null and path_creator.path.has_method("GetPointAtDistance"):
			next_pos = path_creator.path.GetPointAtDistance(distance_travelled + 1.0)
		elif path_creator.has_method("GetPointAtDistance"):
			next_pos = path_creator.GetPointAtDistance(distance_travelled + 1.0)
		elif "curve" in path_creator and path_creator.curve != null:
			var baked_len = path_creator.curve.get_baked_length()
			var dist = fposmod(distance_travelled + 1.0, baked_len) if baked_len > 0.0 else 0.0
			next_pos = path_creator.curve.sample_baked(dist)
		if (next_pos - target_local_pos).length_squared() > 0.001:
			rotation = (next_pos - target_local_pos).angle()
