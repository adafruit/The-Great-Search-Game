extends CanvasLayer

# Make this pause menu process input even when game is paused
func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready() -> void:
	# Hide the menu when the scene starts
	hide_pause_menu()
	
	# Connect UI buttons
	$PanelContainer/MarginContainer/VBoxContainer/ResumeButton.pressed.connect(toggle_pause_menu)
	$PanelContainer/MarginContainer/VBoxContainer/SettingsButton.pressed.connect(show_settings)
	$PanelContainer/MarginContainer/VBoxContainer/QuitButton.pressed.connect(quit_to_main_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# Consume the input event to prevent it from propagating
		get_viewport().set_input_as_handled()
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	if $PanelContainer.visible:
		hide_pause_menu()
	else:
		show_pause_menu()

func show_pause_menu() -> void:
	$PanelContainer.visible = true
	$SettingsPanel.visible = false
	get_tree().paused = true

func hide_pause_menu() -> void:
	$PanelContainer.visible = false
	$SettingsPanel.visible = false
	get_tree().paused = false

func show_settings() -> void:
	$PanelContainer.visible = false
	$SettingsPanel.visible = true

func hide_settings() -> void:
	$SettingsPanel.visible = false
	$PanelContainer.visible = true

func back_to_pause_menu() -> void:
	$SettingsPanel.visible = false
	$PanelContainer.visible = true

func quit_to_main_menu() -> void:
	# Ensure we unpause before changing scene
	get_tree().paused = false
	
	# Change to main menu scene (adjust path as needed)
	SceneTransition.transition_duration = 1.0
	SceneTransition.transition_delay = 0.5
	SceneTransition.change_scene("res://Scenes/adafruit_presents_root.tscn")
