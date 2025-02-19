extends Area2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D


	
func _process(delta): 
		pass

func _on_body_entered(body: Node2D) -> void:
	audio_stream_player_2d.play()
	print("I'm cappy!")
	queue_free()
