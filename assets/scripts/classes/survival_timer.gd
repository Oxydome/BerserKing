class_name SurvivalTimer
extends Node

## Survival Clock HUD Timer ported from Unity Timer.cs.
## Replicates:
##   public TMP_Text TimeObject;
##   public static Timer Instance;
##   public static event GameSecond OnGameSecond;
##   public static event GameMinute OnGameMinute;
##   public string TimeFormat = "mm\\:ss";
##   OnSecond() every 1 second, updating HUD and firing second/minute events.

signal game_second(total_seconds: int)
signal game_minute(total_minutes: int)

# Signal aliases matching Unity event naming convention
signal OnGameSecond(total_seconds: int)
signal OnGameMinute(total_minutes: int)

static var instance : SurvivalTimer = null

static var Instance : SurvivalTimer:
	get: return instance

@export var time_label : Label
@export var time_format : String = "%02d:%02d"
@export var autostart : bool = true

var total_seconds : int = 0
var time_elapsed_accumulator : float = 0.0
var is_running : bool = false

# Uppercase aliases matching Unity C# naming convention
var TimeObject : Label:
	get: return time_label
	set(val): time_label = val

var TimeFormat : String:
	get: return time_format
	set(val): time_format = val

# Native 'Time' is a reserved Godot class, so we use TotalTime and GameTime
var TotalTime : int:
	get: return total_seconds
	set(val): total_seconds = val

var GameTime : int:
	get: return total_seconds
	set(val): total_seconds = val

func _init() -> void:
	Awake()

func _enter_tree() -> void:
	Awake()

func _exit_tree() -> void:
	if instance == self:
		instance = null

func Awake() -> void:
	if instance != null and instance != self and is_instance_valid(instance) and instance.is_inside_tree():
		pass
	else:
		instance = self

func _ready() -> void:
	Start()

func Start() -> void:
	if time_label == null and has_node("TimerLabel"):
		time_label = get_node("TimerLabel")
	elif time_label == null and get_parent() != null and get_parent().has_node("TimerLabel"):
		time_label = get_parent().get_node("TimerLabel")
		
	update_display()
	if autostart:
		is_running = true

func _process(delta: float) -> void:
	if not is_running:
		return
		
	time_elapsed_accumulator += delta
	while time_elapsed_accumulator >= 1.0:
		time_elapsed_accumulator -= 1.0
		OnSecond()

## Unity OnSecond() port
func OnSecond() -> void:
	total_seconds += 1
	update_display()
	
	game_second.emit(total_seconds)
	OnGameSecond.emit(total_seconds)
	
	if total_seconds % 60 == 0:
		var mins = total_seconds / 60
		game_minute.emit(mins)
		OnGameMinute.emit(mins)

func update_display() -> void:
	if time_label != null:
		var mins = total_seconds / 60
		var secs = total_seconds % 60
		time_label.text = time_format % [mins, secs]

func reset_timer() -> void:
	total_seconds = 0
	time_elapsed_accumulator = 0.0
	update_display()
