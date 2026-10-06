class_name HealthBar
extends Control

## UI Health bar component ported from Unity Health.cs.
## Controls a Slider / TextureProgressBar displaying player/entity health.

@export var show_numbers : bool = false

@onready var texture_progress_bar : TextureProgressBar = get_node_or_null("TextureProgressBar")
@onready var health_label : Label = get_node_or_null("HealthLabel")

var current_health : int = 100
var max_health : int = 100

# Accessor for the internal progress bar / slider
var slider : Range:
	get:
		if texture_progress_bar == null and is_instance_valid(self):
			texture_progress_bar = get_node_or_null("TextureProgressBar")
		return texture_progress_bar
	set(val):
		if val is TextureProgressBar:
			texture_progress_bar = val

var slider_bar : Range:
	get: return slider
	set(val): slider = val

func _ready() -> void:
	if texture_progress_bar == null:
		texture_progress_bar = get_node_or_null("TextureProgressBar")
	if health_label == null:
		health_label = get_node_or_null("HealthLabel")
	_refresh_display()

func get_slider() -> Range:
	return slider

func set_slider(val: Range) -> void:
	slider = val

func SetMaxHealth(p_health: int) -> void:
	set_max_health(p_health)

func set_max_health(p_health: int) -> void:
	max_health = maxi(1, p_health)
	current_health = mini(current_health, max_health)
	_refresh_display()

func SetHealth(p_health: int) -> void:
	set_health(p_health)

func set_health(p_health: int) -> void:
	current_health = clampi(p_health, 0, max_health)
	_refresh_display()

func _refresh_display() -> void:
	if slider != null:
		slider.max_value = max_health
		slider.value = current_health
	if health_label == null and is_instance_valid(self):
		health_label = get_node_or_null("HealthLabel")
	if health_label != null:
		if show_numbers:
			health_label.text = "%d / %d" % [current_health, max_health]
			health_label.visible = true
		else:
			health_label.visible = false
