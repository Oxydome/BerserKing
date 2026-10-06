class_name TrailRenderer
extends Line2D

## TrailRenderer component for Godot 4.
## Replicates Unity's TrailRenderer behavior for 2D sprites and characters.
## Emits a fading ribbon trail behind the moving target when emitting is true.

@export var emitting : bool = false:
	set(value):
		emitting = value
		if not is_inside_tree():
			return
		set_physics_process(true)
		set_process(true)

@export var max_points : int = 30
@export var point_lifetime : float = 0.5
@export var min_spawn_distance : float = 4.0
@export var target_path : NodePath

var _points_creation_times : Array[float] = []
var _target_node : Node2D

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	global_rotation = 0.0
	clear_points()
	
	if target_path and has_node(target_path):
		_target_node = get_node(target_path) as Node2D
	if _target_node == null:
		_target_node = get_parent() as Node2D
		
	# Setup default visual properties if not configured
	if width <= 0.0 or is_equal_approx(width, 10.0):
		width = 20.0
		
	if width_curve == null:
		var curve = Curve.new()
		# Start of line (index 0 / tail) is thin, end of line (index N-1 / head) is full width
		curve.add_point(Vector2(0.0, 0.0))
		curve.add_point(Vector2(1.0, 1.0))
		width_curve = curve
		
	if gradient == null:
		var grad = Gradient.new()
		# Index 0 (tail) is transparent, index N-1 (head) is visible
		grad.set_color(0, Color(0.3, 0.7, 1.0, 0.0))
		grad.set_color(1, Color(1.0, 1.0, 1.0, 0.8))
		gradient = grad
		
	joint_mode = Line2D.LINE_JOINT_ROUND
	begin_cap_mode = Line2D.LINE_CAP_ROUND
	end_cap_mode = Line2D.LINE_CAP_ROUND

func _physics_process(_delta: float) -> void:
	_update_trail()

func _update_trail() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if emitting and _target_node != null and is_instance_valid(_target_node):
		var target_pos = _target_node.global_position
		var point_count = get_point_count()
		if point_count == 0 or target_pos.distance_to(get_point_position(point_count - 1)) >= min_spawn_distance:
			add_point(target_pos)
			_points_creation_times.append(current_time)
			
	# Remove points older than point_lifetime or if exceeding max_points
	while _points_creation_times.size() > 0 and (current_time - _points_creation_times[0] > point_lifetime or get_point_count() > max_points):
		if get_point_count() > 0:
			remove_point(0)
		_points_creation_times.pop_front()
		
	if not emitting and get_point_count() == 0:
		set_physics_process(false)
