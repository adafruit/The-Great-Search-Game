extends Node

# Default settings
var settings = {
	"sound_volume": 100,
	"music_volume": 100,
	"fullscreen": false
}

signal settings_changed

# Config file path
const SETTINGS_FILE = "user://settings.cfg"

func _ready() -> void:
	load_settings()

func save_settings() -> void:
	var config = ConfigFile.new()
	
	# Save each setting to the config file
	for key in settings.keys():
		config.set_value("Settings", key, settings[key])
	
	# Save the file
	config.save(SETTINGS_FILE)
	
	# Apply settings
	apply_settings()
	
	# Emit signal for other nodes to respond
	settings_changed.emit()

func load_settings() -> void:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE)
	
	# If the file couldn't be loaded, use default settings
	if error != OK:
		save_settings()
		return
	
	# Load each setting
	for key in settings.keys():
		if config.has_section_key("Settings", key):
			settings[key] = config.get_value("Settings", key)
	
	# Apply settings
	apply_settings()

func apply_settings() -> void:
	# Apply fullscreen
	if OS.has_feature("pc"):
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if settings["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED
		)
	
	# Set sound volumes
	var sound_bus_idx = AudioServer.get_bus_index("Sound")
	var music_bus_idx = AudioServer.get_bus_index("Music")
	
	if sound_bus_idx >= 0:
		AudioServer.set_bus_volume_db(sound_bus_idx, linear_to_db(settings["sound_volume"] / 100.0))
	
	if music_bus_idx >= 0:
		AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(settings["music_volume"] / 100.0))

func update_setting(key: String, value) -> void:
	if settings.has(key):
		settings[key] = value
		save_settings()