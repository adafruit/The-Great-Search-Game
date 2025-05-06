extends Node

# Signal to notify when the pause button is pressed
signal pause_requested

func _input(event: InputEvent) -> void:
	# Check for pause input (ESC key or Start button)
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("startOrMenu"):
		pause_requested.emit()