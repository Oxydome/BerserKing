class_name PathCreator
extends Node2D

## PathCreator spline path component ported from Unity PathCreator asset.
## Generates and samples bezier / spline paths for weapon orbits and follower entities.

@export var radius_x : float = 75.0
@export var radius_y : float = 50.0
@export var point_count : int = 16
@export var is_closed : bool = true

var curve : Curve2D
var _vertex_path : VertexPath

# Inner class mimicking Unity PathCreation.VertexPath
class VertexPath extends RefCounted:
	var curve_ref : Curve2D
	var closed : bool = true
	
	func _init(p_curve: Curve2D, p_closed: bool = true) -> void:
		curve_ref = p_curve
		closed = p_closed
		
	var length : float:
		get:
			return curve_ref.get_baked_length() if curve_ref != null else 0.0
			
	func GetPointAtDistance(distance: float) -> Vector2:
		return get_point_at_distance(distance)
		
	func get_point_at_distance(distance: float) -> Vector2:
		if curve_ref == null or curve_ref.point_count == 0:
			return Vector2.ZERO
		var baked_len = curve_ref.get_baked_length()
		if baked_len <= 0.0:
			return Vector2.ZERO
		var dist = fposmod(distance, baked_len) if closed else clampf(distance, 0.0, baked_len)
		return curve_ref.sample_baked(dist)
		
	func GetRotationAtDistance(distance: float) -> float:
		if curve_ref == null or curve_ref.point_count < 2:
			return 0.0
		var baked_len = curve_ref.get_baked_length()
		var p1 = get_point_at_distance(distance)
		var p2 = get_point_at_distance(distance + 1.0)
		return (p2 - p1).angle()

# Uppercase and alternative aliases matching Unity PathCreator.path
var path : VertexPath:
	get:
		if _vertex_path == null:
			_generate_path()
		return _vertex_path

var Path : VertexPath:
	get: return path

func _ready() -> void:
	if curve == null:
		_generate_path()

func _generate_path() -> void:
	curve = Curve2D.new()
	var step = (TAU) / float(point_count)
	for i in range(point_count):
		var angle = i * step
		var pt = Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
		# Tangent handles for smooth elliptical bezier curvature
		var tangent = Vector2(-sin(angle) * radius_x, cos(angle) * radius_y).normalized() * (step * 0.35 * maxf(radius_x, radius_y))
		curve.add_point(pt, -tangent, tangent)
		
	if is_closed and point_count > 0:
		var start_pt = Vector2(radius_x, 0.0)
		var tangent = Vector2(0.0, radius_y).normalized() * (step * 0.35 * maxf(radius_x, radius_y))
		curve.add_point(start_pt, -tangent, tangent)
		
	_vertex_path = VertexPath.new(curve, is_closed)

## Direct convenience method replicating pathCreator.path.GetPointAtDistance(distance)
func GetPointAtDistance(distance: float) -> Vector2:
	return path.GetPointAtDistance(distance)

func get_point_at_distance(distance: float) -> Vector2:
	return path.get_point_at_distance(distance)
