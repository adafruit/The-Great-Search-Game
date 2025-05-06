extends Camera2D

@export var room_size := Vector2(640, 380)
@export var follow_player := false  # Toggle between room and player following
@export var follow_smoothing := 0.1  # Smoothing factor when following player directly
@export var auto_detect_free_roam := true  # Whether to automatically detect free roam areas
@export var position_adjustment := Vector2(0, 0)  # Direct position adjustment
@export var edge_margin := Vector2(50, 50)  # Margin to prevent elements from clipping

var current_room := Vector2.ZERO
var in_free_roam_area := false  # Track if player is in a free roam area
var target_position := Vector2.ZERO

func _ready() -> void:
	# Connect to all existing free roam areas
	connect_to_free_roam_areas()

func connect_to_free_roam_areas() -> void:
	print("connect_to_free_roam_areas")
	var areas = get_tree().get_nodes_in_group("free_roam_area")
	for area in areas:
		# Make sure we're only connecting to Area2D nodes
		if area is Area2D:
			# Connect to the area's signals
			if !area.body_entered.is_connected(_on_free_roam_area_body_entered):
				area.body_entered.connect(_on_free_roam_area_body_entered)
			if !area.body_exited.is_connected(_on_free_roam_area_body_exited):
				area.body_exited.connect(_on_free_roam_area_body_exited)
		else:
			print("Warning: Node ", area.name, " is in group 'free_roam_area' but is not an Area2D")

func _on_free_roam_area_body_entered(body) -> void:
	# Check if the body that entered is the player
	print("_on_free_roam_area_body_entered")
	if body.is_in_group("player"):
		in_free_roam_area = true

func _on_free_roam_area_body_exited(body) -> void:
	# Check if the body that exited is the player
	print("_on_free_roam_area_body_exited")
	if body.is_in_group("player"):
		in_free_roam_area = false
		
		# When exiting a free roam area and not manually following, snap to current room
		if !follow_player:
			var player = body
			current_room = (player.global_position / room_size).floor()
			target_position = current_room * room_size + (room_size / 2) + position_adjustment
			global_position = target_position

func _process(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
		
	var player = players[0]
	
	# If in a free roam area or manually set to follow player
	if in_free_roam_area or follow_player:
		# Direct player following with smooth movement, plus position adjustment
		target_position = player.global_position + position_adjustment
		
		# Apply edge checking to prevent clipping
		check_screen_edges(player)
		
		global_position = global_position.lerp(target_position, follow_smoothing)
	else:
		# Room-based movement with position adjustment
		var target_room = (player.global_position / room_size).floor()
		
		if target_room != current_room:
			current_room = target_room
			target_position = current_room * room_size + (room_size / 2) + position_adjustment
			global_position = target_position

# Check if elements are near screen edges and adjust camera position
func check_screen_edges(player) -> void:
	# Get the viewport size
	var viewport_size = get_viewport_rect().size
	
	# Calculate screen boundaries in global coordinates
	var screen_left = global_position.x - (viewport_size.x / 2) + edge_margin.x
	var screen_right = global_position.x + (viewport_size.x / 2) - edge_margin.x
	var screen_top = global_position.y - (viewport_size.y / 2) + edge_margin.y
	var screen_bottom = global_position.y + (viewport_size.y / 2) - edge_margin.y
	
	# Get all game elements that need to be visible
	var important_elements = get_tree().get_nodes_in_group("important_visible")
	
	# Include the player as an important element
	important_elements.append(player)
	
	# Check if any important elements are near edges and adjust target position
	for element in important_elements:
		if element.global_position.x < screen_left:
			target_position.x -= (screen_left - element.global_position.x)
		elif element.global_position.x > screen_right:
			target_position.x += (element.global_position.x - screen_right)
			
		if element.global_position.y < screen_top:
			target_position.y -= (screen_top - element.global_position.y)
		elif element.global_position.y > screen_bottom:
			target_position.y += (element.global_position.y - screen_bottom)

# Call this function to toggle between modes (now considers free roam areas)
func toggle_camera_mode() -> void:
	follow_player = !follow_player
	
	if !follow_player and !in_free_roam_area:
		# When switching back to room mode and not in a free roam area, snap to current room
		var player = get_tree().get_nodes_in_group("player")[0]
		current_room = (player.global_position / room_size).floor()
		target_position = current_room * room_size + (room_size / 2) + position_adjustment
		global_position = target_position

# Apply manual position adjustment (can be called from other scripts)
func set_position_adjustment(new_adjustment: Vector2) -> void:
	position_adjustment = new_adjustment
	# Immediately update the camera position
	if !in_free_roam_area and !follow_player:
		var player = get_tree().get_nodes_in_group("player")[0]
		current_room = (player.global_position / room_size).floor()
		target_position = current_room * room_size + (room_size / 2) + position_adjustment
		global_position = target_position

func _draw() -> void:
	var rect = Rect2(current_room, current_room)
	draw_rect(rect, Color(1, 0, 0, 0.3), false, 2.0)
