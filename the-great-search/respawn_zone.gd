extends Area2D
class_name RespawnZone

# Signal to notify when a player enters this respawn zone
signal respawn_point_set(position)

# Called when the node enters the scene tree
# In RespawnZone.gd, modify _ready():
func _ready():
	add_to_group("respawn_zone")
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
		
	var respawn_manager = get_node("/root/RespawnGlobal")
	if respawn_manager:
		connect("respawn_point_set", Callable(respawn_manager, "set_respawn_point"))


# Called when a body enters the respawn zone
func _on_body_entered(body):
	# Check if the entering body is the player
	if body.is_in_group("player"):
		# Emit signal with this respawn zone's position
		emit_signal("respawn_point_set", global_position)
