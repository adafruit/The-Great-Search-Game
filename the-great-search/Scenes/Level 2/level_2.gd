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
		
	# Display welcome message using DialogueView
	var dialogue_view = get_tree().get_first_node_in_group("dialogue_view")
	if dialogue_view:
		dialogue_view.show_dialogue(
			"Fitter. Happier. Ferrite.", 
			"

The elevator door’s sealed tight
Sparky’s at it again!

Collect these three items to override the lock:

• Circuit Playground Express

• Feather RP2040

• BME280 Sensor

",
			" "
		)
		# Mark this as the welcome message so it can be dismissed with the interaction key
		dialogue_view.is_welcome_message = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
