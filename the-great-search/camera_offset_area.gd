extends Area2D
class_name CameraOffsetArea

# Export variables for camera offset adjustments
@export var camera_offset: Vector2 = Vector2(0, 0)
@export var transition_time: float = 0.5
@export var debug_color: Color = Color(0, 0.7, 1, 0.2)  # Light blue semi-transparent
@export var show_debug: bool = true
@export var center_player: bool = false  # New option to center player

# Store original camera offset to restore when exiting
var original_offset: Vector2
var original_anchor_mode: int  # Store original camera anchor mode
var camera: Camera2D
var player: Node2D
var transition_tween: Tween

func _ready() -> void:
	# Add to a distinct group
	add_to_group("camera_offset_area")
	
	# Find the camera in the main_camera group
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if cameras.size() > 0:
		camera = cameras[0]
	else:
		push_error("No camera found in 'main_camera' group!")
	
	print("CameraOffsetArea - Ready at position: ", global_position)
	print("Collision shape size: ", get_child(0).shape.extents if get_child(0) is CollisionShape2D else "No shape found")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Add this to validate signal connections are working
	print("Signal connected: ", body_entered.get_connections())

func _on_body_entered(body: Node2D) -> void:
	print("Player entered camera offset area!!")
	if body.is_in_group("player") and camera != null:
		print("Player entered camera offset area: ", name)
		
		# Store original values
		original_offset = camera.position_adjustment
		if center_player:
			original_anchor_mode = camera.anchor_mode
		
		player = body
		
		# Kill any active tween
		if transition_tween:
			transition_tween.kill()
		
		# Handle camera centering if enabled
		if center_player:
			# Store camera's current settings
			print("Changing camera anchor mode from ", camera.anchor_mode, " to Camera2D.ANCHOR_MODE_DRAG_CENTER")
			
			# Create transition for offset
			transition_tween = create_tween()
			transition_tween.set_trans(Tween.TRANS_CUBIC)
			transition_tween.set_ease(Tween.EASE_OUT)
			transition_tween.tween_method(update_camera_offset, original_offset, camera_offset, transition_time)
			
			# Change anchor mode after a small delay to ensure smooth transition
			await get_tree().create_timer(transition_time * 0.1).timeout
			camera.anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
		else:
			# Just update the offset as before
			print("Changing camera offset from ", camera.position_adjustment, " to ", camera_offset)
			
			# Create transition for offset
			transition_tween = create_tween()
			transition_tween.set_trans(Tween.TRANS_CUBIC)
			transition_tween.set_ease(Tween.EASE_OUT)
			transition_tween.tween_method(update_camera_offset, original_offset, camera_offset, transition_time)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and camera != null:
		print("Player exited camera offset area: ", name)
		
		player = null
		
		# Kill any active tween
		if transition_tween:
			transition_tween.kill()
		
		# Create transition for offset
		transition_tween = create_tween()
		transition_tween.set_trans(Tween.TRANS_CUBIC)
		transition_tween.set_ease(Tween.EASE_OUT)
		
		if center_player:
			print("Restoring camera anchor mode from ", camera.anchor_mode, " to ", original_anchor_mode)
			
			# Start transition
			transition_tween.tween_method(update_camera_offset, camera.position_adjustment, original_offset, transition_time)
			
			# Restore original anchor mode after a short delay
			await get_tree().create_timer(transition_time * 0.9).timeout
			camera.anchor_mode = original_anchor_mode
		else:
			print("Restoring camera offset from ", camera.position_adjustment, " to ", original_offset)
			transition_tween.tween_method(update_camera_offset, camera.position_adjustment, original_offset, transition_time)

# Update the camera offset through the existing set_position_adjustment method
func update_camera_offset(value: Vector2) -> void:
	if camera != null:
		camera.set_position_adjustment(value)

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
