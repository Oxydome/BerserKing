extends CanvasLayer

@onready var inventory := $BoxContainer/Inventory
@onready var survival_timer := get_node_or_null("SurvivalTimer")

var health_bar : HealthBar:
	get:
		if _cached_health_bar == null and is_instance_valid(self):
			_cached_health_bar = find_child("HealthBar", true, false) as HealthBar
		return _cached_health_bar
	set(val):
		_cached_health_bar = val
var _cached_health_bar : HealthBar = null

var timer_label : Label:
	get:
		if _cached_timer_label == null and is_instance_valid(self):
			_cached_timer_label = find_child("TimerLabel", true, false) as Label
		return _cached_timer_label
	set(val):
		_cached_timer_label = val
var _cached_timer_label : Label = null

var has_menu = false

func _get_global() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/Global")
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree and main_loop.root != null:
		return main_loop.root.get_node_or_null("Global")
	return null

func _init() -> void:
	var global = _get_global()
	if global != null:
		global.CurrentGameUI = self

func _enter_tree() -> void:
	var global = _get_global()
	if global != null:
		global.CurrentGameUI = self

func _ready() -> void:
	var global = _get_global()
	if global != null:
		global.CurrentGameUI = self
	_connect_health_bar()

func get_health_bar() -> HealthBar:
	return health_bar

func _connect_health_bar() -> void:
	var bar = get_health_bar()
	if bar == null:
		return
	var global = _get_global()
	var player = global.CurrentPlayer if global != null else null
	if player == null and is_inside_tree():
		player = get_tree().root.find_child("Player", true, false)
	if player != null:
		var p_max = player.max_health if "max_health" in player else 100
		var p_cur = player.health if "health" in player else 100
		bar.set_max_health(p_max)
		bar.set_health(p_cur)
		if player.has_signal("health_changed"):
			var callable = Callable(self, "_on_player_health_changed")
			if not player.health_changed.is_connected(callable):
				player.health_changed.connect(callable)
		if "damage_system" in player and player.damage_system != null:
			player.damage_system.health = bar

func _on_player_health_changed(current: int, max_hp: int) -> void:
	var bar = get_health_bar()
	if bar != null:
		bar.set_max_health(max_hp)
		bar.set_health(current)

func _exit_tree() -> void:
	get_tree().paused = false

func _on_back_button_pressed() -> void:
	var global = _get_global()
	if global != null:
		global.CurrentGameKillCount = 0
		global.CurrentPlayer = null
		global.CurrentLevel = null
		global.CurrentGameUI = null
		get_tree().change_scene_to_file(global.MainMenuScene)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu_old.tscn")
