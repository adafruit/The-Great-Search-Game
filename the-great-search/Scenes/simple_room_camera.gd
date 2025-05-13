extends Camera2D
class_name SimpleRoomCamera

# Room settings
@export var room_size := Vector2(640, 360)
@export var remember_room_positions := true
@export var position_offset := Vector2(0, 0)

# Camera behavior
@export var follow_player := false
@export var follow_smoothing := 0.1
@export_range(0.0, 1.0) var transition_speed := 0.1

# Debug
@export var show_room_borders := false
@export var debug_color := Color(1, 0, 0, 0.3)

# Private variables
var current_room := Vector2i.ZERO
var previous_room := Vector2i.ZERO
var room_positions := {}
var active_tween: Tween

func _ready() -> void:
	# Add to group for easy access by other nodes
	add_to_group("main_camera")
	
	# Initial setup
	var player = get_player()
	if player:
		initialize_position(player.global_position)

# Get the player reference
func get_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

# Initialize camera position at start
func initialize_position(player_pos: Vector2) -> void:
	current_room = get_room_coords(player_pos)
	previous_room = current_room
	
	# Initial camera position (precise room center)
	var target_pos = get_room_center(current_room) + position_offset
	global_position = target_pos
	
	# Store this position
	if remember_room_positions:
		store_room_position(current_room, target_pos)

func _physics_process(delta: float) -> void:
	var player = get_player()
	if not player:
		return
		
	if follow_player:
		# Direct player following
		var target_pos = player.global_position + position_offset
		global_position = global_position.lerp(target_pos, follow_smoothing)
	else:
		# Room-based camera
		var player_room = get_room_coords(player.global_position)
		
		# Only handle room changes
		if player_room != current_room:
			previous_room = current_room
			current_room = player_room
			
			# Get target position (either stored or calculated)
			var target_pos: Vector2
			
			if remember_room_positions and has_room_position(current_room):
				target_pos = get_room_position(current_room)
			else:
				target_pos = get_room_center(current_room) + position_offset
				if remember_room_positions:
					store_room_position(current_room, target_pos)
			
			# Stop any active tweens
			if active_tween and active_tween.is_valid():
				active_tween.kill()
			
			# Create new transition tween
			active_tween = create_tween()
			active_tween.set_trans(Tween.TRANS_CUBIC)
			active_tween.set_ease(Tween.EASE_OUT)
			active_tween.tween_property(self, "global_position", target_pos, transition_speed)

# Return room coordinates for a world position
func get_room_coords(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / room_size.x), floor(world_pos.y / room_size.y))

# Get room center from room coordinates
func get_room_center(room_coords: Vector2i) -> Vector2:
	return Vector2(
		room_coords.x * room_size.x + room_size.x / 2,
		room_coords.y * room_size.y + room_size.y / 2
	)

# Room position storage functions
func get_room_key(room_coords: Vector2i) -> String:
	return "%d,%d" % [room_coords.x, room_coords.y]

func has_room_position(room_coords: Vector2i) -> bool:
	return get_room_key(room_coords) in room_positions

func get_room_position(room_coords: Vector2i) -> Vector2:
	return room_positions[get_room_key(room_coords)]

func store_room_position(room_coords: Vector2i, position: Vector2) -> void:
	room_positions[get_room_key(room_coords)] = position

# External API - force camera update
func force_update() -> void:
	var player = get_player()
	if player:
		var player_room = get_room_coords(player.global_position)
		
		# Force room change
		if player_room == current_room:
			# We're in the same room, so reset position
			var target_pos: Vector2
			
			if remember_room_positions and has_room_position(current_room):
				target_pos = get_room_position(current_room)
			else:
				target_pos = get_room_center(current_room) + position_offset
			
			# Instant position change
			global_position = target_pos
		else:
			# Different room - simulate room change
			previous_room = Vector2i(-9999, -9999)  # Force update
			current_room = player_room
			
			var target_pos: Vector2
			if remember_room_positions and has_room_position(current_room):
				target_pos = get_room_position(current_room)
			else:
				target_pos = get_room_center(current_room) + position_offset
				if remember_room_positions:
					store_room_position(current_room, target_pos)
					
			global_position = target_pos

# External API - set custom position for a room
func set_room_position(room_x: int, room_y: int, position: Vector2) -> void:
	var room_coords = Vector2i(room_x, room_y)
	store_room_position(room_coords, position)
	
	# Update immediately if we're in this room
	if current_room == room_coords:
		global_position = position

# External API - toggle follow mode
func toggle_follow_mode() -> void:
	follow_player = !follow_player
	
	# If switching to room-based, snap immediately
	if !follow_player:
		force_update()

# External API - clear memory
func clear_room_memory() -> void:
	room_positions.clear()

# Debug drawing
func _draw() -> void:
	if show_room_borders:
		# Draw current room boundary
		var room_rect = Rect2(
			Vector2(current_room) * room_size - global_position,
			room_size
		)
		draw_rect(room_rect, debug_color, false, 2.0)
		
		# Draw stored room positions
		for key in room_positions:
			var parts = key.split(",")
			var room_x = int(parts[0])
			var room_y = int(parts[1])
			var room_pos = Vector2(room_x, room_y) 
			var stored_rect = Rect2(
				room_pos * room_size - global_position,
				room_size
			)
			draw_rect(stored_rect, Color(0, 1, 0, 0.2), false, 1.0)
			
			# Draw a dot at the stored camera position
			var stored_pos = room_positions[key] - global_position
			draw_circle(stored_pos, 3, Color(0, 0, 1, 0.5))
	
func _process(_delta: float) -> void:
	if show_room_borders:
		queue_redraw()