extends Area2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var kill_timer: Timer = $KillTimer
@onready var camera_2d: Camera2D = $"../../../../Camera2D"

@export var shake_amount: float = 1.0
@export var shake_duration: float = 0.15

var value: int = 1

func _process(delta): 
		pass

func _on_body_entered(body: Node2D) -> void:
	Global_Score.score += value
	Global_Score.updateScore.emit
	
	if camera_2d:
		shake_camera(camera_2d)
	
	audio_stream_player_2d.play()
	print("Coin Collected")
	kill_timer.start()


func _on_kill_timer_timeout() -> void:

	queue_free()
 
func shake_camera(camera: Camera2D) -> void:
	var shake_tween = get_tree().create_tween()
	var original_offset = camera.offset
	
	for i in range(10):
		var rand_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_tween.tween_property(camera, "offset", original_offset + rand_offset, shake_duration / 10.0)
	
	shake_tween.tween_property(camera, "offset", original_offset, shake_duration / 10.0)
