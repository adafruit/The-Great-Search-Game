extends Camera2D

@export var room_size := Vector2(640, 360)
@export var follow_player := false  # Toggle between room and player following
@export var follow_smoothing := 0.1  # Smoothing factor when following player directly
@export var position_adjustment := Vector2(0, 0)  # Optional offset adjustment

var current_room := Vector2.ZERO
var target_position := Vector2.ZERO
var room_positions := {}  # Dictionary to store camera positions for each room

func _ready() -> void:
	# Initialize with the current room
	var players = get_tree().get_nodes_in_group("player")
	if !players.is_empty():
		var player = players[0]
		snap_to_room(player.global_position)

func _process(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
		
	var player = players[0]
	
	if follow_player:
		# Direct player following with smooth movement
		target_position = player.global_position + position_adjustment
		global_position = global_position.lerp(target_position, follow_smoothing)
	else:
		# Room-based movement
		var target_room = (player.global_position / room_size).floor()
		
		if target_room != current_room:
			# Player entered a new room
			current_room = target_room
			snap_to_room(player.global_position)

# Snap camera to the center of the room containing the given position
func snap_to_room(position: Vector2) -> void:
	# Calculate room coordinates
	current_room = (position / room_size).floor()
	var room_key = str(current_room.x) + "," + str(current_room.y)
	
	# Check if we have a stored position for this room
	if room_key in room_positions:
		target_position = room_positions[room_key]
	else:
		# Calculate exact room center
		target_position = (current_room * room_size) + (room_size / 2) + position_adjustment
		# Store for future use
		room_positions[room_key] = target_position
		
	# Instantly move camera to target position
	global_position = target_position
	
# Call this to force camera update (useful after scene transitions)
func force_update() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if !players.is_empty():
		# Reset current room to force update
		current_room = Vector2(-9999, -9999)
		snap_to_room(players[0].global_position)

# Toggle between room-based and player following modes
func toggle_follow_mode() -> void:
	follow_player = !follow_player
	
	# If switching to room-based, snap immediately
	if !follow_player:
		var players = get_tree().get_nodes_in_group("player")
		if !players.is_empty():
			snap_to_room(players[0].global_position)

# Set a custom position for a specific room (useful for special rooms)
func set_room_position(room_x: int, room_y: int, position: Vector2) -> void:
	var room_key = str(room_x) + "," + str(room_y)
	room_positions[room_key] = position
	
	# Update immediately if we're in this room
	if current_room.x == room_x and current_room.y == room_y:
		target_position = position
		global_position = position

# Clear all stored room positions
func clear_room_memory() -> void:
	room_positions.clear()
