extends Area2D

@onready var timer: Timer = $Timer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var respawn_manager = get_node("/root/RespawnGlobal")

func _ready() -> void:
	#audio_stream_player_2d.stop()
	print("Lightning Ready")



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("DEAD - Lightning Cannon")
		respawn_player(body)
		

func respawn_player(player: Node2D):
	respawn_manager.respawn_player(player)

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
	
func respawn():
	respawn_manager.respawn_player(self)
