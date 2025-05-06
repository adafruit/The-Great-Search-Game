extends Area2D

@export_file("*.tscn") var load_level: String = ""
@export var transition_duration: float = 1.0
@export var transition_delay: float = 0.5  # Delay between fade out and fade in
@onready var timer: Timer = $Timer

func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	if load_level.is_empty():
		return
	
	SceneTransition.transition_duration = 1.0  # Customize if needed
	SceneTransition.transition_delay = 0.5    # Customize if needed
	SceneTransition.change_scene(load_level)

func transition_to_scene() -> void:
	print("Creating fade overlay")
	
	# Create a persistent CanvasLayer that won't be destroyed with scene change
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.name = "TransitionLayer"
	get_tree().root.add_child(canvas_layer)
	
	# Create fade overlay
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)  # Start transparent
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(fade)
	
	# Ensure it covers the entire viewport
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fade.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	print("Starting fade out tween")
	# Create tween for fade out
	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 1), transition_duration)
	await tween.finished
	
	print("Fade out complete, waiting for delay")
	# Use timer for first delay
	timer.wait_time = transition_delay
	timer.one_shot = true
	timer.start()
	await timer.timeout
	
	print("Delay complete, changing scene")
	# Change scene using the path
	get_tree().change_scene_to_file(load_level)
	
	# For the second delay, create a new timer that won't be destroyed with the scene
	var delay_timer = Timer.new()
	delay_timer.wait_time = transition_delay
	delay_timer.one_shot = true
	canvas_layer.add_child(delay_timer)
	delay_timer.start()
	
	print("Scene changed, waiting for delay")
	await delay_timer.timeout
	
	print("Starting fade in")
	# Create tween for fade in
	tween = create_tween()
	tween.tween_property(fade, "color", Color(0, 0, 0, 0), transition_duration)
	await tween.finished
	
	print("Fade in complete, removing overlay")
	# Remove the transition layer
	canvas_layer.queue_free()
