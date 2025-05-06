extends Area2D
class_name RoomSizeChanger

# Export the new room size to set when player enters this area
@export var new_room_size: Vector2 = Vector2(200, 540)
@export var enable_player_following: bool = true  # Whether to follow the player while in this area
@export var follow_smoothing: float = 0.1  # Smoothing factor for player following
@export var debug_color: Color = Color(1, 0.5, 0, 0.2)  # Orange semi-transparent for debugging
@export var show_debug: bool = true  # Whether to show the debug visualization

# Store the original room size and follow state to restore when exiting
var original_room_size: Vector2
var original_follow_state: bool
var camera: Camera2D

func _ready() -> void:
	# Add this area to a distinct group
	add_to_group("room_size_changer")
	
	print("RoomSizeChanger - Ready")
	
	# Connect signals 
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Find the main camera
	await get_tree().process_frame
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if !cameras.is_empty():
		camera = cameras[0]
		original_room_size = camera.room_size
	else:
		push_warning("No camera found in 'main_camera' group. Add your camera to this group.")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and camera != null:
		print("Player entered room size changer area: ", name)
		print("Changing room size from ", camera.room_size, " to ", new_room_size)
		
		# Store the original settings
		original_room_size = camera.room_size
		original_follow_state = camera.follow_player
		
		# Change the room size
		camera.room_size = new_room_size
		
		# Enable player following if specified
		if enable_player_following:
			camera.follow_player = true
			camera.follow_smoothing = follow_smoothing
		
		# If not following player, force the camera to recalculate its position
		if !camera.follow_player:
			var player = body
			camera.current_room = (player.global_position / new_room_size).floor()
			var target_pos = camera.current_room * new_room_size + (new_room_size / 2)
			camera.global_position = target_pos

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and camera != null:
		print("Player exited room size changer area: ", name)
		print("Restoring room size from ", camera.room_size, " to ", original_room_size)
		
		# Restore the original settings
		camera.room_size = original_room_size
		camera.follow_player = original_follow_state
		
		# Force the camera to recalculate its position based on the restored room size
		if !camera.follow_player:
			var player = body
			camera.current_room = (player.global_position / original_room_size).floor()
			var target_pos = camera.current_room * original_room_size + (original_room_size / 2)
			camera.global_position = target_pos

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
