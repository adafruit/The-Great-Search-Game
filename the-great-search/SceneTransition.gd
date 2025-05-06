# SceneTransition.gd - Add this as an autoload/singleton
extends CanvasLayer

signal transition_completed

var transition_duration: float = 1.0
var transition_delay: float = 0.5

func _ready():
	# Set layer priority and make it not visible at first
	layer = 100
	visible = false
	
	# Create the fade overlay once at startup
	var fade = ColorRect.new()
	fade.name = "FadeOverlay"
	fade.color = Color(0, 0, 0, 0) # Start transparent
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fade.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(fade)

func change_scene(target_scene: String) -> void:
	visible = true
	var fade = $FadeOverlay
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), transition_duration)
	await tween.finished
	
	# Delay
	await get_tree().create_timer(transition_delay).timeout
	
	# Change scene
	get_tree().change_scene_to_file(target_scene)
	
	# Delay
	await get_tree().create_timer(transition_delay).timeout
	
	# Fade in
	tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 0), transition_duration)
	await tween.finished
	
	visible = false
	transition_completed.emit()
