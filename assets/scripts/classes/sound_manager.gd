class_name SoundManager
extends Node

## Sound & Music Manager hooking all 50 misc SFX and soundtrack to Godot audio buses.
## Ported/adapted for BerserKing's Main.mixer audio pipeline.

signal sfx_played(sfx_index: int, sfx_name: String)

static var instance : SoundManager = null

static var Instance : SoundManager:
	get: return instance

const BGM_PATH = "res://assets/music/bacround_music/Armor_-_Berserker_Mode.mp3"
const SFX_DIR = "res://assets/music/sounds/"

var bgm_player : AudioStreamPlayer
var sfx_players : Array[AudioStreamPlayer] = []
var sfx_catalog : Dictionary = {}
var max_sfx_pool : int = 8

func _init() -> void:
	Awake()
	load_sfx_catalog()

func _enter_tree() -> void:
	Awake()

func Awake() -> void:
	if instance != null and instance != self:
		push_warning("Only one SoundManager!")
	else:
		instance = self

func _ready() -> void:
	# Set up BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	if ResourceLoader.exists(BGM_PATH):
		var bgm_stream = load(BGM_PATH) as AudioStream
		bgm_player.stream = bgm_stream
		
	# Set up SFX player pool
	for i in range(max_sfx_pool):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
		
	load_sfx_catalog()

func load_sfx_catalog() -> void:
	for i in range(1, 51):
		var sfx_name = "MI_SFX %02d" % i
		var path = "%s%s.mp3" % [SFX_DIR, sfx_name]
		if ResourceLoader.exists(path):
			sfx_catalog[i] = path
			sfx_catalog[sfx_name] = path

## Play background music (Armor - Berserker Mode)
func play_bgm(loop: bool = true) -> void:
	if bgm_player.stream == null and ResourceLoader.exists(BGM_PATH):
		bgm_player.stream = load(BGM_PATH) as AudioStream
	if bgm_player.stream != null and not bgm_player.playing:
		bgm_player.play()

func stop_bgm() -> void:
	if bgm_player != null and bgm_player.playing:
		bgm_player.stop()

## Play one of the 50 SFX by index (1 to 50)
func play_sfx(index: int, volume_db: float = 0.0) -> void:
	var sfx_name = "MI_SFX %02d" % index
	play_sfx_by_name(sfx_name, volume_db)

## Play SFX by name e.g. "MI_SFX 01"
func play_sfx_by_name(sfx_name: String, volume_db: float = 0.0) -> void:
	if not sfx_catalog.has(sfx_name):
		var path = "%s%s.mp3" % [SFX_DIR, sfx_name]
		if ResourceLoader.exists(path):
			sfx_catalog[sfx_name] = path
		else:
			return
			
	var stream = load(sfx_catalog[sfx_name]) as AudioStream
	if stream == null:
		return
		
	# Find free player in pool
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.play()
			var idx = int(sfx_name.replace("MI_SFX ", ""))
			sfx_played.emit(idx, sfx_name)
			return
			
	# If all busy, steal the first one
	if not sfx_players.is_empty():
		var p = sfx_players[0]
		p.stream = stream
		p.volume_db = volume_db
		p.play()
		var idx = int(sfx_name.replace("MI_SFX ", ""))
		sfx_played.emit(idx, sfx_name)

func set_master_volume(linear_val: float) -> void:
	var bus_idx = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		if linear_val <= 0.0001:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))

func has_sfx(id: Variant) -> bool:
	return sfx_catalog.has(id)

func get_sfx_path(id: Variant) -> String:
	if sfx_catalog.has(id):
		return sfx_catalog[id]
	return ""
