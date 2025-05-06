extends Control

func _ready() -> void:
	# Connect the back button
	$MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)
	
	# Connect settings controls
	$MarginContainer/VBoxContainer/SoundVolume/HSlider.value_changed.connect(_on_sound_volume_changed)
	$MarginContainer/VBoxContainer/MusicVolume/HSlider.value_changed.connect(_on_music_volume_changed)
	$MarginContainer/VBoxContainer/Fullscreen/CheckBox.toggled.connect(_on_fullscreen_toggled)
	
	# Load current settings
	_load_settings_values()
	
	# Connect to settings changed signal
	SettingsManager.settings_changed.connect(_load_settings_values)

func _load_settings_values() -> void:
	# Update UI controls to reflect current settings
	$MarginContainer/VBoxContainer/SoundVolume/HSlider.value = SettingsManager.settings["sound_volume"]
	$MarginContainer/VBoxContainer/MusicVolume/HSlider.value = SettingsManager.settings["music_volume"]
	$MarginContainer/VBoxContainer/Fullscreen/CheckBox.button_pressed = SettingsManager.settings["fullscreen"]

func _on_back_button_pressed() -> void:
	# Let the parent pause menu know we want to go back
	get_parent().back_to_pause_menu()

func _on_sound_volume_changed(value: float) -> void:
	SettingsManager.update_setting("sound_volume", value)

func _on_music_volume_changed(value: float) -> void:
	SettingsManager.update_setting("music_volume", value)

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	SettingsManager.update_setting("fullscreen", button_pressed)