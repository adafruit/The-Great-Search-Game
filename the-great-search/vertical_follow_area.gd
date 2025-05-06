extends Area2D
class_name VerticalFollowArea

@export var room_override := false  # Whether to override room size when player enters
@export var new_room_size := Vector2(640, 360)  # New room size if override enabled
@export var follow_smoothing := 0.1  # Smoothing factor for vertical movement
@export var debug_color := Color(0, 0.5, 1, 0.2)  # Blue semi-transparent for debugging
@export var show_debug := true  # Whether to show the debug visualization

# Store the original room size to restore when exiting
var original_room_size := Vector2.ZERO
var camera: Camera2D

func _ready() -> void:
	# Add this area to the vertical_follow_area group
	add_to_group("vertical_follow_area")
	
	# Find the main camera
	await get_tree().process_frame
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if !cameras.is_empty():
		camera = cameras[0]
		original_room_size = camera.room_size
	else:
		push_warning("No camera found in 'main_camera' group. Add your camera to this group.")
	
	# Connect signals directly since camera handles connection differently
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Queue redraw for debug visualization
	if show_debug:
		queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and camera != null:
		print("Player entered vertical follow area: ", name)
		
		# Store the original room size if we're overriding it
		if room_override:
			original_room_size = camera.room_size
			camera.room_size = new_room_size
			print("Changing room size from ", original_room_size, " to ", new_room_size)
			
			# Force camera to recalculate current room with new size
			var player = body
			camera.current_room = (player.global_position / new_room_size).floor()
		
		# Set vertical following in the camera
		# (Camera handles the actual following logic)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and camera != null:
		print("Player exited vertical follow area: ", name)
		
		# Restore the original room size if we overrode it
		if room_override:
			print("Restoring room size from ", camera.room_size, " to ", original_room_size)
			camera.room_size = original_room_size
			
			# Force camera to recalculate room position with restored size
			if !camera.follow_player:
				var player = body
				camera.current_room = (player.global_position / original_room_size).floor()
				var target_pos = camera.current_room * original_room_size + (original_room_size / 2)
				camera.global_position = target_pos
		
		# Vertical following is turned off in camera's signal handler

# Optional debug visualization
func _draw() -> void:
	if show_debug:
		for child in get_children():
			if child is CollisionShape2D:
				if child.shape is RectangleShape2D:
					var rect = Rect2(-child.shape.extents, child.shape.extents * 2)
					draw_rect(rect, debug_color, true)
				elif child.shape is CircleShape2D:
					draw_circle(Vector2.ZERO, child.shape.radius, debug_color)
