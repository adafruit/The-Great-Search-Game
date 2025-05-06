extends Area2D
class_name CameraLimitArea

# Export variables for camera limits
@export var left_limit: float = -10000000
@export var right_limit: float = 10000000
@export var top_limit: float = -10000000
@export var bottom_limit: float = 10000000
@export var transition_time: float = 0.5
@export var debug_color: Color = Color(1, 0.2, 0.2, 0.2)  # Red semi-transparent
@export var show_debug: bool = true

# Store original limits to restore when exiting
var original_limits: Rect2
var camera: Camera2D
var player: Node2D
var transition_tween: Tween

func _ready() -> void:
	# Add to a distinct group
	add_to_group("camera_limit_area")
	
	print("CameraLimitArea - Ready at position: ", global_position)
	
	# Add debug info for collision shape
	var shape_info = "No shape found"
	for child in get_children():
		if child is CollisionShape2D:
			if child.shape is RectangleShape2D:
				shape_info = child.shape.extents
			elif child.shape is CircleShape2D:
				shape_info = "radius: " + str(child.shape.radius)
	print("Collision shape size: ", shape_info)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Print signal connections for debugging
	print("Signal connected: ", body_entered.get_connections())
	
	# Find the camera
	await get_tree().process_frame
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if !cameras.is_empty():
		camera = cameras[0]
		# Store original camera limits
		original_limits = Rect2(
			camera.limit_left,
			camera.limit_top,
			camera.limit_right - camera.limit_left,
			camera.limit_bottom - camera.limit_top
		)
	else:
		push_warning("No camera found in 'main_camera' group. Add your camera to this group.")

func _on_body_entered(body: Node2D) -> void:
	print("Body entered: ", body.name, " - In player group: ", body.is_in_group("player"))
	
	if body.is_in_group("player") and camera != null:
		
		player = body
		
		# Kill any active tween
		if transition_tween:
			transition_tween.kill()
		
		# Create and start a new tween
		transition_tween = create_tween()
		transition_tween.set_trans(Tween.TRANS_CUBIC)
		transition_tween.set_ease(Tween.EASE_OUT)
		
		# Tween each limit separately
		transition_tween.tween_method(set_left_limit, camera.limit_left, left_limit, transition_time)
		transition_tween.parallel().tween_method(set_top_limit, camera.limit_top, top_limit, transition_time)
		transition_tween.parallel().tween_method(set_right_limit, camera.limit_right, right_limit, transition_time)
		transition_tween.parallel().tween_method(set_bottom_limit, camera.limit_bottom, bottom_limit, transition_time)

func _on_body_exited(body: Node2D) -> void:
	print("Body exited: ", body.name)
	
	if body.is_in_group("player") and camera != null:
		print("Player exited camera limit area: ", name)
		print("Restoring camera limits to original values")
		
		player = null
		
		# Kill any active tween
		if transition_tween:
			transition_tween.kill()
		
		# Create and start a new tween to restore original limits
		transition_tween = create_tween()
		transition_tween.set_trans(Tween.TRANS_CUBIC)
		transition_tween.set_ease(Tween.EASE_OUT)
		
		# Tween each limit separately
		transition_tween.tween_method(set_left_limit, camera.limit_left, original_limits.position.x, transition_time)
		transition_tween.parallel().tween_method(set_top_limit, camera.limit_top, original_limits.position.y, transition_time)
		transition_tween.parallel().tween_method(set_right_limit, camera.limit_right, original_limits.position.x + original_limits.size.x, transition_time)
		transition_tween.parallel().tween_method(set_bottom_limit, camera.limit_bottom, original_limits.position.y + original_limits.size.y, transition_time)

# Helper methods to update individual limits
func set_left_limit(value: float) -> void:
	if camera != null:
		camera.limit_left = value

func set_right_limit(value: float) -> void:
	if camera != null:
		camera.limit_right = value

func set_top_limit(value: float) -> void:
	if camera != null:
		camera.limit_top = value

func set_bottom_limit(value: float) -> void:
	if camera != null:
		camera.limit_bottom = value

# Process function to check player proximity (for debugging)
func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if !players.is_empty():
		var distance = global_position.distance_to(players[0].global_position)
		if distance < 100:  # Within 100 pixels
			print("Player near limit area, distance:", distance)
	
	# Queue redraw to update visualization
	queue_redraw()

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
		
		# Visualize the camera limits
		if camera != null:
			# Draw the future camera limits (relative to this node's position)
			var limit_rect = Rect2(
				left_limit - global_position.x,
				top_limit - global_position.y,
				right_limit - left_limit,
				bottom_limit - top_limit
			)
			draw_rect(limit_rect, Color(1, 0, 0, 0.1), false, 2.0)
