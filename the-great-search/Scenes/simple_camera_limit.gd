extends Area2D
class_name SimpleCameraLimit

# Limit settings
@export_group("Camera Limits")
@export var left_limit: float = -10000000
@export var right_limit: float = 10000000
@export var top_limit: float = -10000000
@export var bottom_limit: float = 10000000
@export var auto_size_from_shape: bool = true

# Camera behavior options
@export_group("Camera Behavior")
@export var override_follow_mode: bool = false
@export var follow_mode: bool = false
@export var restore_on_exit: bool = true

# Room overrides
@export_group("Room Settings")
@export var apply_room_offset: bool = false
@export var room_offset: Vector2 = Vector2.ZERO

# Transition settings
@export_group("Transitions")
@export var transition_time: float = 0.5
@export var transition_type: Tween.TransitionType = Tween.TRANS_CUBIC
@export var transition_ease: Tween.EaseType = Tween.EASE_OUT

# Debug display
@export_group("Debug")
@export var show_debug: bool = true
@export var debug_color: Color = Color(1, 0.5, 0, 0.3)

# Private variables
var camera: Camera2D
var player: Node2D
var original_limits: Rect2
var original_follow_mode: bool
var limit_tween: Tween
var is_active: bool = false

func _ready() -> void:
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up debug visuals
	if show_debug:
		if !is_processing():
			set_process(true)
	
	# Get limits from shape if needed
	if auto_size_from_shape:
		calculate_limits_from_shape()
	
	# Find camera after a short delay to ensure it's set up
	call_deferred("_find_camera")

func _find_camera() -> void:
	await get_tree().process_frame
	
	# Try to find camera in main_camera group
	var cameras = get_tree().get_nodes_in_group("main_camera")
	if cameras.size() > 0:
		if cameras[0] is Camera2D:
			camera = cameras[0]
		store_camera_settings()
	else:
		push_warning("No camera found in 'main_camera' group")

func store_camera_settings() -> void:
	if camera:
		# Store current limits
		original_limits = Rect2(
			camera.limit_left,
			camera.limit_top,
			camera.limit_right - camera.limit_left,
			camera.limit_bottom - camera.limit_top
		)
		
		# Store follow mode if available
		original_follow_mode = false
		if camera.get("follow_player") != null:
			original_follow_mode = camera.follow_player

func calculate_limits_from_shape() -> void:
	for child in get_children():
		if child is CollisionShape2D and child.shape:
			if child.shape is RectangleShape2D:
				var shape_extents = child.shape.extents
				var shape_position = child.position
				
				# Calculate limits based on rectangle shape
				left_limit = global_position.x + shape_position.x - shape_extents.x
				right_limit = global_position.x + shape_position.x + shape_extents.x
				top_limit = global_position.y + shape_position.y - shape_extents.y
				bottom_limit = global_position.y + shape_position.y + shape_extents.y
				
				break
			elif child.shape is CircleShape2D:
				var radius = child.shape.radius
				var shape_position = child.position
				
				# Calculate limits based on circle shape
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
		
		# Apply room offset if enabled
		if apply_room_offset and camera is SimpleRoomCamera:
			# Calculate which rooms are covered by this area
			var room_size = camera.room_size
			var top_left = Vector2i(
				int(floor(left_limit / room_size.x)),
				int(floor(top_limit / room_size.y))
			)
			var bottom_right = Vector2i(
				int(floor(right_limit / room_size.x)),
				int(floor(bottom_limit / room_size.y))
			)
			
			# Set offset for each room in the area
			for x in range(top_left.x, bottom_right.x + 1):
				for y in range(top_left.y, bottom_right.y + 1):
					var room_center = Vector2(
						x * room_size.x + room_size.x / 2,
						y * room_size.y + room_size.y / 2
					)
					
					# Set custom position using room center + offset
					camera.set_room_position(x, y, room_center + room_offset)
		
		# Apply follow mode override if needed
		if override_follow_mode and camera.get("follow_player") != null:
			camera.follow_player = follow_mode
		
		# Apply camera limits with smooth transition
		apply_camera_limits()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and body == player and camera and is_active:
		is_active = false
		print("Player exited camera limit area: ", name)
		
		# Restore follow mode if needed
		if override_follow_mode and restore_on_exit and camera.get("follow_player") != null:
			camera.follow_player = original_follow_mode
		
		# Restore original limits
		restore_camera_limits()
		
		# Force camera update if needed
		if camera.has_method("force_update") and !camera.get("follow_player"):
			camera.force_update()
		
		player = null

func apply_camera_limits() -> void:
	# Stop active tween
	if limit_tween and limit_tween.is_valid():
		limit_tween.kill()
	
	# Create new tween
	limit_tween = create_tween()
	limit_tween.set_trans(transition_type)
	limit_tween.set_ease(transition_ease)
	
	# Apply all limits with tweening
	limit_tween.tween_method(set_left_limit, camera.limit_left, left_limit, transition_time)
	limit_tween.parallel().tween_method(set_top_limit, camera.limit_top, top_limit, transition_time)
	limit_tween.parallel().tween_method(set_right_limit, camera.limit_right, right_limit, transition_time)
	limit_tween.parallel().tween_method(set_bottom_limit, camera.limit_bottom, bottom_limit, transition_time)

func restore_camera_limits() -> void:
	# Stop active tween
	if limit_tween and limit_tween.is_valid():
		limit_tween.kill()
	
	# Create new tween
	limit_tween = create_tween()
	limit_tween.set_trans(transition_type)
	limit_tween.set_ease(transition_ease)
	
	# Restore original limits with tweening
	limit_tween.tween_method(
		set_left_limit, 
		camera.limit_left, 
		original_limits.position.x, 
		transition_time
	)
	limit_tween.parallel().tween_method(
		set_top_limit, 
		camera.limit_top, 
		original_limits.position.y, 
		transition_time
	)
	limit_tween.parallel().tween_method(
		set_right_limit, 
		camera.limit_right, 
		original_limits.position.x + original_limits.size.x, 
		transition_time
	)
	limit_tween.parallel().tween_method(
		set_bottom_limit, 
		camera.limit_bottom, 
		original_limits.position.y + original_limits.size.y, 
		transition_time
	)

# Helper methods to update limits
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

# Debug drawing
func _draw() -> void:
	if show_debug:
		# Draw shape outline
		for child in get_children():
			if child is CollisionShape2D:
				if child.shape is RectangleShape2D:
					var rect = Rect2(
						child.position - child.shape.extents,
						child.shape.extents * 2
					)
					draw_rect(rect, debug_color, true)
					
					# Draw border
					draw_rect(rect, Color(1, 1, 1, 0.5), false, 2.0)
				elif child.shape is CircleShape2D:
					draw_circle(child.position, child.shape.radius, debug_color)
					
					# Draw border
					draw_circle(child.position, child.shape.radius, Color(1, 1, 1, 0.5), false)
		
		# Draw camera limits
		var limit_rect = Rect2(
			Vector2(left_limit, top_limit) - global_position,
			Vector2(right_limit - left_limit, bottom_limit - top_limit)
		)
		draw_rect(limit_rect, Color(0, 1, 0, 0.2), false, 2.0)

func _process(_delta: float) -> void:
	if show_debug:
		queue_redraw()

# Public API - for manual activation
func activate() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and camera and !is_active:
		_on_body_entered(players[0])

func deactivate() -> void:
	if player and camera and is_active:
		_on_body_exited(player)

# Update limits if shape changes
func update_limits() -> void:
	if auto_size_from_shape:
		calculate_limits_from_shape()
	
	if is_active and camera:
		apply_camera_limits()
