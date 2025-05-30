extends Button

var track_index: int = -1
var track_title: String = ""

func _ready() -> void:
	pressed.connect(_on_pressed)
	
	# Style the button
	add_theme_font_size_override("font_size", 16)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
func set_track(index: int, title: String, unlocked: bool) -> void:
	track_index = index
	track_title = title
	text = title
	disabled = not unlocked
	
	if not unlocked:
		text = "🔒 " + title
	else:
		text = title

func _on_pressed() -> void:
	if track_index >= 0:
		MusicManager.play_track(track_index)