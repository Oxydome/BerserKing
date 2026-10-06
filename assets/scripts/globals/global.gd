extends Node

#region Variables
#Scenes
@export_file var PlayScene := "res://scenes/game.tscn"
@export_file var OptionsScene := "res://scenes/options_menu.tscn"
@export_file var MainMenuScene := "res://scenes/main_menu_old.tscn"
@export_file var GameScene := "res://scenes/game.tscn"
@export_file var GameUIScene := "res://scenes/game_ui.tscn"
@export_file var LevelSelectScene := "res://scenes/levels.tscn"
@export_file var LevelsScene := "res://scenes/levels.tscn"
@export_file var CharacterSelectScene := "res://scenes/character_select.tscn"
@export_file var CurrentLevelPath : String = "res://assets/levels/castle.tscn"
@export_file var CurrentCharacterPath : String = "res://assets/textures/sprites/player/windman.tres"
@export var CurrentCharacterName : String = "Wind Warrior"

#Current Entities
@export var CurrentGameUI : CanvasLayer
@export var CurrentLevel : TileMap
@export var CurrentPlayer : CharacterBody2D
@export var CurrentItemManager : Node
@export var CurrentEntityManager : Node
@export var CurrentMenuHandler : Node
@export var CurrentGameKillCount : int

@export var despawn_distance : int = 1200

# Signals for chunk generation and entity/item lifecycle
@warning_ignore("unused_signal")
signal generate_inited(level_data, lock_to_entity)
@warning_ignore("unused_signal")
signal generate_stopped(level_data, lock_to_entity)
@warning_ignore("unused_signal")
signal player_died(player)
@warning_ignore("unused_signal")
signal entity_died(entity)
@warning_ignore("unused_signal")
signal item_picked_up(item, player)

# Audio signals
@warning_ignore("unused_signal")
signal play_sfx(sound_name, position)
@warning_ignore("unused_signal")
signal play_music(music_name)

var is_paused : bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _get_tree_safe() -> SceneTree:
	if is_inside_tree() and get_tree() != null:
		return get_tree()
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop
	return null

func change_scene(transition_scene_path: String, target_scene_path: String, anim_name: String = "fade_center") -> void:
	var tree = _get_tree_safe()
	if tree == null:
		return

	if not ResourceLoader.exists(transition_scene_path) or not ResourceLoader.exists(target_scene_path):
		if ResourceLoader.exists(target_scene_path):
			tree.change_scene_to_file(target_scene_path)
		return
		
	var trans_scene = load(transition_scene_path)
	if trans_scene == null:
		tree.change_scene_to_file(target_scene_path)
		return
		
	var transition_node = trans_scene.instantiate()
	if tree.root != null:
		tree.root.add_child(transition_node)
	
	var anim_player = transition_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player != null and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		await anim_player.animation_finished
	
	tree.change_scene_to_file(target_scene_path)
	
	if anim_player != null and anim_player.has_animation(anim_name):
		anim_player.play_backwards(anim_name)
		await anim_player.animation_finished
	
	if is_instance_valid(transition_node):
		transition_node.queue_free()
