extends Node

signal track_changed(track_name: String)
signal playback_state_changed(is_playing: bool)
signal track_position_updated(position: float, duration: float)
signal music_player_activated(active: bool)

# Reference to the scene's background music player
var scene_music_player: AudioStreamPlayer = null
var scene_music_position: float = 0.0
var scene_music_was_playing: bool = false

# Music track information
var music_tracks = [
	{
		"title": "GPIO Dreams",
		"path": "res://Assests/Music/GPIO Dreams.mp3",
		"artist": "The Great Search",
		"unlocked": true
	},
	{
		"title": "NeoPixel Fever",
		"path": "res://Assests/Music/NeoPixel Fever.mp3",
		"artist": "The Great Search",
		"unlocked": true
	},
	{
		"title": "Voltage Regret",
		"path": "res://Assests/Music/Voltage Regret.mp3",
		"artist": "The Great Search",
		"unlocked": true
	},
	{
		"title": "Blue Smoke Waltz",
		"path": "res://Assests/Music/Blue Smoke Waltz.mp3",
		"artist": "The Great Search",
		"unlocked": true
	},
	{
		"title": "Follow Your Technolust",
		"path": "res://Assests/Music/Follow Your Technolust.mp3",
		"artist": "The Great Search",
		"unlocked": true
	},
	{
		"title": "Hack the Planet",
		"path": "res://Assests/Music/Hack the Planet.mp3",
		"artist": "The Great Search",
		"unlocked": true
	},
	{
		"title": "Upload Complete (Run It Again)",
		"path": "res://Assests/Music/Upload Complete (Run It Again).mp3",
		"artist": "The Great Search",
		"unlocked": true
	},
	{
		"title": "Serial Overdrive",
		"path": "res://Assests/Music/Serial Overdrive.mp3",
		"artist": "The Great Search",
		"unlocked": true
	}
]

# Audio player
var audio_player: AudioStreamPlayer
var current_track_index: int = -1
var is_playing: bool = false
var loop_mode: bool = false
var shuffle_mode: bool = false
var track_history = []
var update_timer: Timer

# Settings and saved state
const MUSIC_SAVE_FILE = "user://music_player.cfg"

func _ready() -> void:
	# Initialize audio player
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Music"
	add_child(audio_player)
	
	# Connect signals
	audio_player.finished.connect(_on_track_finished)
	
	# Set up position update timer
	update_timer = Timer.new()
	update_timer.wait_time = 0.1 # Update 10 times per second
	update_timer.timeout.connect(_on_update_timer)
	add_child(update_timer)
	update_timer.start()
	
	# Load saved music player state
	load_music_player_state()

func _on_update_timer() -> void:
	if is_playing and audio_player.stream != null:
		var position = audio_player.get_playback_position()
		var duration = audio_player.stream.get_length()
		track_position_updated.emit(position, duration)

func play_track(index: int) -> void:
	if index < 0 or index >= music_tracks.size():
		return
		
	if not music_tracks[index].unlocked:
		print("Track not unlocked: ", music_tracks[index].title)
		return
	
	# Pause scene music when starting a track
	pause_scene_music()
	
	# Load the stream resource
	var stream = load(music_tracks[index].path)
	if stream:
		current_track_index = index
		audio_player.stream = stream
		audio_player.play()
		is_playing = true
		
		# Add to history
		track_history.push_back(index)
		
		# Update UI
		track_changed.emit(music_tracks[index].title)
		playback_state_changed.emit(true)
		
		# Save state
		save_music_player_state()
	else:
		print("Failed to load track: ", music_tracks[index].path)

func play_pause() -> void:
	if current_track_index == -1 and not is_playing:
		# No track selected, play first available
		play_track(0)
	elif is_playing:
		audio_player.stream_paused = true
		is_playing = false
		playback_state_changed.emit(false)
	else:
		audio_player.stream_paused = false
		is_playing = true
		playback_state_changed.emit(true)
	
	# Save state
	save_music_player_state()

func stop() -> void:
	audio_player.stop()
	is_playing = false
	playback_state_changed.emit(false)
	
	# Resume scene music when music player stops
	resume_scene_music()
	
	# Save state
	save_music_player_state()

func next_track() -> void:
	var next_index = current_track_index
	
	if shuffle_mode:
		# Pick a random track that's not the current one
		var available_indices = []
		for i in range(music_tracks.size()):
			if i != current_track_index and music_tracks[i].unlocked:
				available_indices.append(i)
				
		if available_indices.size() > 0:
			next_index = available_indices[randi() % available_indices.size()]
	else:
		# Find next unlocked track
		var found = false
		var start_index = (current_track_index + 1) % music_tracks.size()
		next_index = start_index
		
		while not found:
			if music_tracks[next_index].unlocked:
				found = true
			else:
				next_index = (next_index + 1) % music_tracks.size()
				if next_index == start_index:
					break
	
	play_track(next_index)

func prev_track() -> void:
	if track_history.size() > 1:
		# Remove current track
		track_history.pop_back()
		# Get previous track
		var prev_index = track_history.pop_back()
		play_track(prev_index)
	else:
		# Just restart current track
		audio_player.seek(0)

func seek(position: float) -> void:
	if audio_player.stream:
		audio_player.seek(position)

func toggle_loop() -> void:
	loop_mode = !loop_mode
	save_music_player_state()

func toggle_shuffle() -> void:
	shuffle_mode = !shuffle_mode
	save_music_player_state()

func _on_track_finished() -> void:
	if loop_mode:
		# Replay current track
		audio_player.play()
	else:
		# Play next track
		next_track()

func unlock_track(track_title: String) -> void:
	for i in range(music_tracks.size()):
		if music_tracks[i].title == track_title:
			music_tracks[i].unlocked = true
			save_music_player_state()
			return

func save_music_player_state() -> void:
	var config = ConfigFile.new()
	
	config.set_value("Player", "current_track", current_track_index)
	config.set_value("Player", "is_playing", is_playing)
	config.set_value("Player", "loop_mode", loop_mode)
	config.set_value("Player", "shuffle_mode", shuffle_mode)
	
	# Save unlocked tracks
	var unlocked_tracks = []
	for i in range(music_tracks.size()):
		if music_tracks[i].unlocked:
			unlocked_tracks.append(music_tracks[i].title)
	
	config.set_value("Tracks", "unlocked", unlocked_tracks)
	
	config.save(MUSIC_SAVE_FILE)

func load_music_player_state() -> void:
	var config = ConfigFile.new()
	var error = config.load(MUSIC_SAVE_FILE)
	
	if error != OK:
		# Default: all tracks unlocked
		for track in music_tracks:
			track.unlocked = true
		return
	
	# Load player settings
	if config.has_section_key("Player", "current_track"):
		current_track_index = config.get_value("Player", "current_track")
	
	if config.has_section_key("Player", "loop_mode"):
		loop_mode = config.get_value("Player", "loop_mode")
		
	if config.has_section_key("Player", "shuffle_mode"):
		shuffle_mode = config.get_value("Player", "shuffle_mode")
	
	# Load unlocked tracks
	if config.has_section_key("Tracks", "unlocked"):
		var unlocked = config.get_value("Tracks", "unlocked")
		
		# First set all to locked
		for track in music_tracks:
			track.unlocked = false
			
		# Then unlock the saved ones
		for track in music_tracks:
			if unlocked.has(track.title):
				track.unlocked = true
	else:
		# Default: all tracks unlocked
		for track in music_tracks:
			track.unlocked = true
	
	# Restore playback if needed
	if config.has_section_key("Player", "is_playing"):
		var was_playing = config.get_value("Player", "is_playing")
		
		if was_playing and current_track_index >= 0 and current_track_index < music_tracks.size():
			play_track(current_track_index)
			
func get_current_track_info() -> Dictionary:
	if current_track_index >= 0 and current_track_index < music_tracks.size():
		return music_tracks[current_track_index]
	return {}
	
# Method to find and store the scene's background music player
func find_scene_music_player() -> void:
	# Look for AudioStreamPlayer in the current scene
	var scene_root = get_tree().current_scene
	if scene_root:
		# First try to find a direct child AudioStreamPlayer
		for child in scene_root.get_children():
			if child is AudioStreamPlayer:
				scene_music_player = child
				print("Found scene music player: ", child.name)
				return
		
		# If not found, search deeper
		scene_music_player = find_audio_player_recursive(scene_root)
		if scene_music_player:
			print("Found scene music player (recursive): ", scene_music_player.name)

# Recursive search for AudioStreamPlayer
func find_audio_player_recursive(node: Node) -> AudioStreamPlayer:
	for child in node.get_children():
		if child is AudioStreamPlayer:
			return child
		
		var result = find_audio_player_recursive(child)
		if result:
			return result
	
	return null

# Called when music player UI is opened
func pause_scene_music() -> void:
	# Find the scene's music player if not already set
	if not scene_music_player:
		find_scene_music_player()
	
	if scene_music_player:
		# Store if it was playing
		scene_music_was_playing = not scene_music_player.stream_paused and scene_music_player.playing
		
		if scene_music_was_playing:
			# Store position before pausing
			scene_music_position = scene_music_player.get_playback_position()
			scene_music_player.stream_paused = true
			print("Scene music paused at position: ", scene_music_position)
			
	# Emit signal that music player is active
	music_player_activated.emit(true)

# Called when music player UI is closed
func resume_scene_music() -> void:
	if scene_music_player and scene_music_was_playing:
		scene_music_player.stream_paused = false
		print("Scene music resumed at position: ", scene_music_position)
	
	# Emit signal that music player is no longer active
	music_player_activated.emit(false)
	
# Called when scene changes
func reset_scene_music_reference() -> void:
	scene_music_player = null
	scene_music_was_playing = false