extends SubViewportContainer

@onready var player := $"../Player"
@onready var mirror_player := $SubViewport/MirrorPlayer

func _process(_delta: float) -> void:
	if player != null and mirror_player != null and player.has_node("AnimatedSprite2D"):
		mirror_player.flip_h = !player.get_node("AnimatedSprite2D").flip_h
		mirror_player.global_position = player.global_position
