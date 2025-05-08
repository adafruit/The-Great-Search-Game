extends Node

# Store the current respawn point
var current_respawn_point: Vector2 = Vector2.ZERO
# Default respawn point in case no respawn zone was triggered
@export var default_respawn_point: Vector2 = Vector2.ZERO
# Death animation parameters
@export var fade_out_time: float = 0.2
@export var respawn_delay: float = 0.1
@export var fade_in_time: float = 0.1

# Signal for player death
signal player_died
signal player_respawned

func _ready():
	# Initialize with the default respawn point
	current_respawn_point = default_respawn_point
	
# Update the current respawn point
func set_respawn_point(position: Vector2):
	current_respawn_point = position
	
# Get the current respawn point
func get_respawn_point() -> Vector2:
	return current_respawn_point
	
# Respawn the player at the current respawn point with fading effect
func respawn_player(player: Node2D):
	if not player:
		return
		
	# Emit the player_died signal
	player_died.emit()
	
	# Pause the game briefly during death animation
	var original_time_scale = Engine.time_scale
	Engine.time_scale = 0.5  # Slow motion effect
	
	# Disable player's physics and input handling during death animation
	if player is CharacterBody2D:
		player.set_physics_process(false)
		player.set_process_input(false)
	
	# Create fade tween
	var tween = player.create_tween()
	tween.tween_property(player, "modulate:a", 0.0, fade_out_time)
	
	# Wait for fade out to complete
	await tween.finished
	
	# Move player to respawn point (while invisible)
	player.global_position = current_respawn_point
	
	# Wait for respawn delay
	await player.get_tree().create_timer(respawn_delay).timeout
	
	# Create fade in tween
	tween = player.create_tween()
	tween.tween_property(player, "modulate:a", 1.0, fade_in_time)
	
	# Re-enable physics and input
	if player is CharacterBody2D:
		player.set_physics_process(true)
		player.set_process_input(true)
	
	# Restore original time scale
	Engine.time_scale = original_time_scale
	
	# Emit player respawned signal
	player_respawned.emit()
