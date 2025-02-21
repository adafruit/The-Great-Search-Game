extends Area2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var kill_timer: Timer = $AudioStreamPlayer2D/KillTimer

func _process(delta): 
		pass

func _on_body_entered(body: Node2D) -> void:
	print("I'm mho!")
	audio_stream_player_2d.play()
	


func _on_kill_timer_timeout() -> void:
	queue_free()
