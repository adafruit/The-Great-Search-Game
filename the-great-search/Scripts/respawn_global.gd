extends Node

# Store the current respawn point
var current_respawn_point: Vector2 = Vector2.ZERO
# Default respawn point in case no respawn zone was triggered
@export var default_respawn_point: Vector2 = Vector2.ZERO

func _ready():
	# Initialize with the default respawn point
	current_respawn_point = default_respawn_point
	
# Update the current respawn point
func set_respawn_point(position: Vector2):
	current_respawn_point = position
	
# Get the current respawn point
func get_respawn_point() -> Vector2:
	return current_respawn_point
	
# Respawn the player at the current respawn point
func respawn_player(player: Node2D):
	player.global_position = current_respawn_point
