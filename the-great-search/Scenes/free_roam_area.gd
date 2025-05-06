extends Area2D
#class_name RoomSizeChanger

# Export the new room size to set when player enters this area
@export var new_room_size: Vector2 = Vector2(640, 360)
@export var enable_player_following: bool = true  # Whether to follow the player while in this area
@export var follow_smoothing: float = 0.1  # Smoothing factor for player following
@export var debug_color: Color = Color(1, 0.5, 0, 0.2)  # Orange semi-transparent for debugging
@export var show_debug: bool = true  # Whether to show the debug visualization

# Camera constraint options
@export_enum("None", "Horizontal_Only", "Vertical_Only") var movement_constraint: int = 0
@export var fixed_axis_position: float = 0.0  # Fixed position for the constrained axis

# Store the original room size and follow state to restore when exiting
var original_room_size: Vector2
var original_follow_state: bool
var camera: Camera2D
var player: Node2D
var is_constraining: bool = false
var initial_fixed_position: float = 0.0  # Store the initial fixed position when player enters

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
		
		# Store reference to player
		player = body
		
		# Change the room size
		camera.room_size = new_room_size
		
		# Enable player following if specified
		if enable_player_following:
			camera.follow_player = true
			camera.follow_smoothing = follow_smoothing
			
			# Start constraining movement if needed
			if movement_constraint > 0:
				is_constraining = true
				
				# Set the initial fixed position
				if fixed_axis_position != 0.0:
					initial_fixed_position = fixed_axis_position
				else:
					# Use current camera position as the fixed position
					if movement_constraint == 1:  # Horizontal Only
						initial_fixed_position = camera.global_position.y
					elif movement_constraint == 2:  # Vertical Only
						initial_fixed_position = camera.global_position.x
		
		# If not following player, force the camera to recalculate its position
		if !camera.follow_player:
			camera.current_room = (player.global_position / new_room_size).floor()
			var target_pos = camera.current_room * new_room_size + (new_room_size / 2)
			camera.global_position = target_pos

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and camera != null:
		print("Player exited room size changer area: ", name)
		print("Restoring room size from ", camera.room_size, " to ", original_room_size)
		
		# Stop constraining
		is_constraining = false
		player = null
		
		# Restore the original settings
		camera.room_size = original_room_size
		camera.follow_player = original_follow_state
		
		# Force the camera to recalculate its position based on the restored room size
		if !camera.follow_player:
			camera.current_room = (body.global_position / original_room_size).floor()
			var target_pos = camera.current_room * original_room_size + (original_room_size / 2)
			camera.global_position = target_pos

func _process(delta: float) -> void:
	# Apply constraints if needed
	if is_constraining and player != null and camera != null and camera.follow_player:
		apply_movement_constraints()

func apply_movement_constraints() -> void:
	# Calculate where the camera would move to follow the player
	var target_position = camera.global_position.lerp(player.global_position, camera.follow_smoothing)
	
	if movement_constraint == 1:  # Horizontal Only
		# Only update the X position, keep Y fixed
		camera.global_position.x = target_position.x
		camera.global_position.y = initial_fixed_position
		
	elif movement_constraint == 2:  # Vertical Only
		# Only update the Y position, keep X fixed
		camera.global_position.x = initial_fixed_position
		camera.global_position.y = target_position.y

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
