extends Control

signal settings_requested

# Make this pause menu process input even when game is paused
func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_menu") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_cancel"):
		# Consume the input event to prevent it from propagating
		get_viewport().set_input_as_handled()


func _ready() -> void:
	# Show the menu when the scene starts
	visible = true
	
	# Connect UI buttons
	%Play.pressed.connect(to_gameplay)
	#%SettingsButton.pressed.connect(func(): settings_requested.emit())
	#%QuitButton.pressed.connect(quit_to_main_menu)

func to_gameplay() -> void:
	# Ensure we unpause before changing scene
	
	get_tree().paused = false
	
	# Change to main menu scene
	SceneTransition.transition_duration = 1.0
	SceneTransition.transition_delay = 0.5
	SceneTransition.change_scene("res://Scenes/main_root.tscn")

func quit_to_main_menu() -> void:
	# Ensure we unpause before changing scene
	get_tree().paused = false
	
	# Change to main menu scene
	SceneTransition.transition_duration = 1.0
	SceneTransition.transition_delay = 0.5
	SceneTransition.change_scene("res://Scenes/adafruit_presents_root.tscn")
