extends Control

signal settings_requested

@onready var pause_menu: Control = $"."

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("startOrMenu"):
		print("Menu key pressed")
		toggle_pause_menu()


# Make this pause menu process input even when game is paused
func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_menu") or event.is_action_pressed("ui_cancel"):
		# Consume the input event to prevent it from propagating
		get_viewport().set_input_as_handled()
		toggle_pause_menu()

func _ready() -> void:
	# Hide the menu when the scene starts
	visible = false
	get_parent().process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect UI buttons
	%ResumeButton.pressed.connect(toggle_pause_menu)
	%SettingsButton.pressed.connect(func(): settings_requested.emit())
	%QuitButton.pressed.connect(quit_to_main_menu)

func toggle_pause_menu() -> void:
	# Toggle visibility
	print("MENU PRESSED")
	visible = !visible
	
	# Toggle game pause
	get_tree().paused = visible
	
	# Print debug info
	print("Gameplay Menu toggled. Visible: ", visible, " Paused: ", get_tree().paused)

func quit_to_main_menu() -> void:
	# Ensure we unpause before changing scene
	get_tree().paused = false
	
	# Change to main menu scene
	SceneTransition.transition_duration = 1.0
	SceneTransition.transition_delay = 0.5
	SceneTransition.change_scene("res://Scenes/adafruit_presents_root.tscn")
