extends Control

# UI references
@onready var track_title: Label = $Container/MainPanel/VBoxContainer/TrackInfo/Title
@onready var track_artist: Label = $Container/MainPanel/VBoxContainer/TrackInfo/Artist
@onready var progress_bar: ProgressBar = $Container/MainPanel/VBoxContainer/Controls/ProgressBar
@onready var time_elapsed: Label = $Container/MainPanel/VBoxContainer/Controls/TimeInfo/TimeElapsed
@onready var time_total: Label = $Container/MainPanel/VBoxContainer/Controls/TimeInfo/TimeTotal
@onready var play_button: Button = $Container/MainPanel/VBoxContainer/Controls/ButtonsRow/PlayButton
@onready var prev_button: Button = $Container/MainPanel/VBoxContainer/Controls/ButtonsRow/PrevButton
@onready var next_button: Button = $Container/MainPanel/VBoxContainer/Controls/ButtonsRow/NextButton
@onready var loop_button: Button = $Container/MainPanel/VBoxContainer/Controls/ButtonsRow/LoopButton
@onready var shuffle_button: Button = $Container/MainPanel/VBoxContainer/Controls/ButtonsRow/ShuffleButton
@onready var track_list: VBoxContainer = $Container/SidePanel/ScrollContainer/TrackList
@onready var back_button: Button = $Container/BackButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Track button scene
var track_button_scene = preload("res://Scenes/UI/music_track_button.tscn")

# State
var seeking: bool = false
var track_buttons = []
var current_track_button: Button = null

func _ready() -> void:
	# Initialize UI
	update_player_controls()
	populate_track_list()
	
	# Connect signals
	MusicManager.track_changed.connect(_on_track_changed)
	MusicManager.playback_state_changed.connect(_on_playback_state_changed)
	MusicManager.track_position_updated.connect(_on_track_position_updated)
	
	play_button.pressed.connect(_on_play_button_pressed)
	prev_button.pressed.connect(_on_prev_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
	loop_button.pressed.connect(_on_loop_button_pressed)
	shuffle_button.pressed.connect(_on_shuffle_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	progress_bar.gui_input.connect(_on_progress_bar_input)
	
	# Pause scene music when opening the music player
	if not MusicManager.is_playing:
		MusicManager.pause_scene_music()
	
	# Animate opening
	if animation_player:
		animation_player.play("open")

func update_player_controls() -> void:
	# Update loop and shuffle button appearance
	loop_button.button_pressed = MusicManager.loop_mode
	shuffle_button.button_pressed = MusicManager.shuffle_mode
	
	# Update play/pause button icon
	if MusicManager.is_playing:
		play_button.text = "⏸"
	else:
		play_button.text = "▶"
	
	# Update track info
	var track_info = MusicManager.get_current_track_info()
	if not track_info.is_empty():
		track_title.text = track_info.title
		track_artist.text = track_info.artist
	else:
		track_title.text = "No Track Selected"
		track_artist.text = ""

func populate_track_list() -> void:
	# Clear any existing buttons
	for button in track_buttons:
		button.queue_free()
	track_buttons.clear()
	
	# Create a button for each track
	for i in range(MusicManager.music_tracks.size()):
		var track = MusicManager.music_tracks[i]
		var track_button = track_button_scene.instantiate()
		
		# Set up the button
		track_button.set_track(i, track.title, track.unlocked)
		track_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Add to list
		track_list.add_child(track_button)
		track_buttons.append(track_button)
		
		# Highlight current track
		if i == MusicManager.current_track_index:
			track_button.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))
			current_track_button = track_button

func _on_track_button_pressed(index: int) -> void:
	MusicManager.play_track(index)

func _on_track_changed(track_name: String) -> void:
	# Update the UI with new track info
	update_player_controls()
	
	# Update track list highlight
	if current_track_button:
		current_track_button.remove_theme_color_override("font_color")
	
	if MusicManager.current_track_index >= 0 and MusicManager.current_track_index < track_buttons.size():
		current_track_button = track_buttons[MusicManager.current_track_index]
		current_track_button.add_theme_color_override("font_color", Color(0.9, 0.6, 0.1))

func _on_playback_state_changed(is_playing: bool) -> void:
	update_player_controls()

func _on_track_position_updated(position: float, duration: float) -> void:
	if not seeking and duration > 0:
		progress_bar.value = position / duration
		
		# Update time labels
		time_elapsed.text = format_time(position)
		time_total.text = format_time(duration)

func format_time(seconds: float) -> String:
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%d:%02d" % [minutes, secs]

func _on_play_button_pressed() -> void:
	MusicManager.play_pause()

func _on_prev_button_pressed() -> void:
	MusicManager.prev_track()

func _on_next_button_pressed() -> void:
	MusicManager.next_track()

func _on_loop_button_pressed() -> void:
	MusicManager.toggle_loop()
	update_player_controls()

func _on_shuffle_button_pressed() -> void:
	MusicManager.toggle_shuffle()
	update_player_controls()

func _on_progress_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				seeking = true
				
				# Calculate seek position
				var mouse_x = event.position.x
				var seek_percent = mouse_x / progress_bar.size.x
				var track_duration = MusicManager.audio_player.stream.get_length()
				var seek_position = seek_percent * track_duration
				
				# Seek to position
				MusicManager.seek(seek_position)
			else:
				seeking = false

func _on_back_button_pressed() -> void:
	# Stop music player and resume scene music if needed
	if MusicManager.is_playing:
		MusicManager.stop()
	else:
		# Just resume the scene music
		MusicManager.resume_scene_music()
	
	if animation_player:
		animation_player.play_backwards("open")
		await animation_player.animation_finished
	
	# Return to previous screen
	queue_free()
