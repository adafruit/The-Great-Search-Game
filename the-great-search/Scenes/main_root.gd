extends Node2D

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
# Reference to the respawn manager - you'll need to create this singleton first
@onready var respawn_manager = get_node("/root/RespawnGlobal")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_stream_player.play()
	
	# Find all respawn zones in the scene and connect them to the respawn manager
	var respawn_zones = get_tree().get_nodes_in_group("respawn_zone")
	
	# Connect each respawn zone to the respawn manager
	for zone in respawn_zones:
		if zone is RespawnZone:
			zone.connect("respawn_point_set", Callable(respawn_manager, "set_respawn_point"))
	
	# Optional: Set initial respawn point based on player's starting position
	# If you have a player node in your scene
	var player = get_tree().get_first_node_in_group("player")
	if player:
		respawn_manager.set_respawn_point(player.global_position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
