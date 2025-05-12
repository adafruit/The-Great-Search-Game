extends Area2D
#class_name ImprovedCameraLimitArea

# Camera limit settings
@export_group("Camera Limits")
@export var left_limit: float = -10000000
@export var right_limit: float = 10000000
@export var top_limit: float = -10000000
@export var bottom_limit: float = 10000000

# Transition settings
@export_group("Transition Settings")
@export var transition_time: float = 0.5
@export var transition_type: Tween.TransitionType = Tween.TRANS_CUBIC
@export var ease_type: Tween.EaseType = Tween.EASE_OUT
@export var auto_size_from_shape: bool = true  # Auto-calculate limits from shape

# Camera modes
@export_group("Camera Behavior")
@export var override_camera_follow: bool = false  # Whether to force camera mode
@export var camera_follow_mode: bool = false  # True = follow player, False = room-based
@export var restore_camera_mode: bool = true  # Restore camera mode on exit

# Zoom settings
@export_group("Zoom Settings")
@export var override_zoom: bool = false
@export var target_zoom: Vector2 = Vector2(1, 1)
@export var zoom_transition_time: float = 0.7  # Can be different from position transition

# Visual settings
@export_group("Visual Settings")
@export var debug_color: Color = Color(1, 0.2, 0.2, 0.2)  # Red semi-transparent
@export var show_debug: bool = true

# Private variables
var original_limits: Rect2
var original_zoom: Vector2
var original_follow_mode: bool
var camera: Camera2D
var player: Node2D
var transition_tween: Tween
var zoom_tween: Tween
var is_active: bool = false

func _ready() -> void:
	# Add to a distinct group
	add_to_group("camera_limit_area")
	
	# Connect signals safely
	if !body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	if !body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	# Auto-calculate limits from collision shape if enabled
	if auto_size_from_shape:
		calculate_limits_from_shape()
	
	# Store the camera reference
	call_deferred("_setup_camera")

func _setup_camera() -> void:
	await get_tree().process_frame
	
	# First try to get camera from main_camera group
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if !cameras.is_empty():
		camera = cameras[0]
	
	# If not found, look for any Camera2D
	if !camera:
		var viewport_cameras = get_viewport().get_children_of_type(Camera2D)
		if viewport_cameras.size() > 0:
			camera = viewport_cameras[0]
			push_warning("Camera not found in 'main_camera' group. Using first Camera2D found.")
	
	if camera:
		# Store original camera limits
		store_original_camera_settings()
	else:
		push_error("No camera found! Add your camera to 'main_camera' group.")

func store_original_camera_settings() -> void:
	if camera:
		# Store limits
		original_limits = Rect2(
			camera.limit_left,
			camera.limit_top,
			camera.limit_right - camera.limit_left,
			camera.limit_bottom - camera.limit_top
		)
		
		# Store zoom
		original_zoom = camera.zoom
		
		# Store follow mode if we can determine it
		if camera.has_method("is_following_player"):
			original_follow_mode = camera.is_following_player()
		elif camera.get_script() and camera.get_script().has_source_code():
			if "follow_player" in camera:
				original_follow_mode = camera.follow_player
			else:
				original_follow_mode = false  # Default assumption

func calculate_limits_from_shape() -> void:
	for child in get_children():
		if child is CollisionShape2D and child.shape:
			if child.shape is RectangleShape2D:
				var shape_extents = child.shape.extents
				var shape_position = child.position
				
				# Calculate limits based on shape
				left_limit = global_position.x + shape_position.x - shape_extents.x
				right_limit = global_position.x + shape_position.x + shape_extents.x
				top_limit = global_position.y + shape_position.y - shape_extents.y
				bottom_limit = global_position.y + shape_position.y + shape_extents.y
				
				print("Auto-calculated limits: L=", left_limit, " R=", right_limit, 
					  " T=", top_limit, " B=", bottom_limit)
				break
			elif child.shape is CircleShape2D:
				var radius = child.shape.radius
				var shape_position = child.position
				
				# Calculate limits based on circular shape
				left_limit = global_position.x + shape_position.x - radius
				right_limit = global_position.x + shape_position.x + radius
				top_limit = global_position.y + shape_position.y - radius
				bottom_limit = global_position.y + shape_position.y + radius
				break

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and camera and !is_active:
		is_active = true
		player = body
		
		print("Player entered camera limit area: ", name)
		
		# Store original camera settings if not already stored
		if original_limits.size == Vector2.ZERO:
			store_original_camera_settings()
		
		# Apply camera mode override if needed
		if override_camera_follow and camera.has_method("set_follow_player"):
			camera.set_follow_player(camera_follow_mode)
		elif override_camera_follow and camera.get_script() and "follow_player" in camera:
			camera.follow_player = camera_follow_mode
		
		# Apply camera limits
		apply_camera_limits()
		
		# Apply zoom if needed
		if override_zoom:
			apply_camera_zoom()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body == player and camera and is_active:
		is_active = false
		
		print("Player exited camera limit area: ", name)
		
		# Restore original camera limits
		restore_camera_limits()
		
		# Restore zoom if needed
		if override_zoom:
			restore_camera_zoom()
		
		# Restore camera mode if needed
		if override_camera_follow and restore_camera_mode:
			if camera.has_method("set_follow_player"):
				camera.set_follow_player(original_follow_mode)
			elif camera.get_script() and "follow_player" in camera:
				camera.follow_player = original_follow_mode
		
		player = null

func apply_camera_limits() -> void:
	# Kill any active tween
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
	
	# Create and start a new tween
	transition_tween = create_tween()
	transition_tween.set_trans(transition_type)
	transition_tween.set_ease(ease_type)
	
	# Tween each limit separately
	transition_tween.tween_method(set_left_limit, camera.limit_left, left_limit, transition_time)
	transition_tween.parallel().tween_method(set_top_limit, camera.limit_top, top_limit, transition_time)
	transition_tween.parallel().tween_method(set_right_limit, camera.limit_right, right_limit, transition_time)
	transition_tween.parallel().tween_method(set_bottom_limit, camera.limit_bottom, bottom_limit, transition_time)

func restore_camera_limits() -> void:
	# Kill any active tween
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
	
	# Create and start a new tween
	transition_tween = create_tween()
	transition_tween.set_trans(transition_type)
	transition_tween.set_ease(ease_type)
	
	# Tween each limit separately
	transition_tween.tween_method(set_left_limit, camera.limit_left, original_limits.position.x, transition_time)
	transition_tween.parallel().tween_method(set_top_limit, camera.limit_top, original_limits.position.y, transition_time)
	transition_tween.parallel().tween_method(set_right_limit, camera.limit_right, 
		original_limits.position.x + original_limits.size.x, transition_time)
	transition_tween.parallel().tween_method(set_bottom_limit, camera.limit_bottom, 
		original_limits.position.y + original_limits.size.y, transition_time)

func apply_camera_zoom() -> void:
	# Kill any active zoom tween
	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()
	
	# Create and start a new zoom tween
	zoom_tween = create_tween()
	zoom_tween.set_trans(transition_type)
	zoom_tween.set_ease(ease_type)
	zoom_tween.tween_property(camera, "zoom", target_zoom, zoom_transition_time)

func restore_camera_zoom() -> void:
	# Kill any active zoom tween
	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()
	
	# Create and start a new zoom tween
	zoom_tween = create_tween()
	zoom_tween.set_trans(transition_type)
	zoom_tween.set_ease(ease_type)
	zoom_tween.tween_property(camera, "zoom", original_zoom, zoom_transition_time)

# Helper methods to update individual limits
func set_left_limit(value: float) -> void:
	if camera:
		camera.limit_left = value

func set_right_limit(value: float) -> void:
	if camera:
		camera.limit_right = value

func set_top_limit(value: float) -> void:
	if camera:
		camera.limit_top = value

func set_bottom_limit(value: float) -> void:
	if camera:
		camera.limit_bottom = value

# Optional debug visualization
func _draw() -> void:
	if show_debug:
		# Draw the collision shape
		for child in get_children():
			if child is CollisionShape2D:
				if child.shape is RectangleShape2D:
					var rect = Rect2(-child.shape.extents + child.position, 
									child.shape.extents * 2)
					draw_rect(rect, debug_color, true)
				elif child.shape is CircleShape2D:
					draw_circle(child.position, child.shape.radius, debug_color)
		
		# Visualize the camera limits
		if camera:
			# Draw the current camera limits (relative to this node's position)
			var limit_rect = Rect2(
				left_limit - global_position.x,
				top_limit - global_position.y,
				right_limit - left_limit,
				bottom_limit - top_limit
			)
			draw_rect(limit_rect, Color(0, 1, 0, 0.2), false, 2.0)
			
			# Draw label showing area name


func _process(_delta: float) -> void:
	if show_debug:
		queue_redraw()

# Public methods to manually activate/deactivate the area
func activate() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if !players.is_empty() and camera:
		_on_body_entered(players[0])

func deactivate() -> void:
	if player and camera:
		_on_body_exited(player)

# Add a method to force update limits if the shape changes
func update_limits() -> void:
	if auto_size_from_shape:
		calculate_limits_from_shape()
	
	# If active, apply the new limits
	if is_active and camera:
		apply_camera_limits()


func _on_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	pass # Replace with function body.


func _on_area_shape_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	pass # Replace with function body.


func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	pass # Replace with function body.


func _on_body_shape_exited(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	pass # Replace with function body.


func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass # Replace with function body.
