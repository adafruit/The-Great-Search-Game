extends Node2D

@export_file("*.tscn") var next_scene: String = ""
@export var auto_transition: bool = true
@export var auto_transition_time: float = 3.0

@onready var transition_timer: Timer = $"Transition timer"

func _ready() -> void:
	# If auto transition is enabled, start the timer
	if auto_transition:
		print("Auto transition enabled, waiting for " + str(auto_transition_time) + " seconds")
		transition_timer.wait_time = auto_transition_time
		transition_timer.one_shot = true
		transition_timer.start()
		transition_timer.timeout.connect(trigger_transition)

# Trigger the transition using the global SceneTransition singleton
func trigger_transition() -> void:
	print("Triggering transition to: " + next_scene)
	
	if next_scene.is_empty():
		print("ERROR: next_scene is empty. Cannot transition.")
		return
	
	# Use the existing global SceneTransition singleton that works
	SceneTransition.transition_duration = 1.0  # Customize if needed
	SceneTransition.transition_delay = 0.5    # Customize if needed
	SceneTransition.change_scene(next_scene)
