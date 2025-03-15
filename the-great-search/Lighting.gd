extends Area2D

@onready var timer: Timer = $Timer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	#audio_stream_player_2d.stop()
	print("Lightning Ready")


func _on_body_entered(body: Node2D) -> void:
	print("DEAD - Lightning")
	Engine.time_scale = 0.4
	timer.start()

func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
