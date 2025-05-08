extends Node2D

# Nodes
@onready var beam_holder = $Position2D
@onready var timer = $Timer
@onready var beam_collision = $Area2D/CollisionShape2D
@onready var beam_light = $Light2D
@onready var damage_timer = $damageTimer
@onready var cycle_timer = $CycleDelayTimer
@onready var respawn_manager = get_node_or_null("/root/RespawnGlobal")
@onready var area_2d = $Area2D

# Get all animated sprites
@onready var sprites = [
	$Position2D/AnimatedSprite2D,
	$Position2D/AnimatedSprite2D2,
	$Position2D/AnimatedSprite2D4,
	$Position2D/AnimatedSprite2D3,
	$Position2D/AnimatedSprite2D5,
	$Position2D/AnimatedSprite2D6,
	$Position2D/AnimatedSprite2D8,
	$Position2D/AnimatedSprite2D7
]

# Configuration
@export var cycle_time: float = 5.0  # Total time for one full cycle
@export var lightning_duration: float = 0.2  # How long each lightning flash lasts
@export var lightning_delay: float = 0.1  # Delay between lightning flashes
@export var beam_duration: float = 1.0  # How long the beam stays on

# State
var is_beam_active = false
var current_lightning_index = 0
var beam_complete = false

func _ready():
	# Setup timers
	timer.wait_time = cycle_time
	damage_timer.wait_time = beam_duration
	
	# Connect signals
	timer.timeout.connect(_start_animation_sequence)
	damage_timer.timeout.connect(_end_beam)
	cycle_timer.timeout.connect(_restart_cycle)
	
	# Connect area signals
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	
	# Hide all sprites initially
	for sprite in sprites:
		if sprite:
			sprite.visible = false
			# Connect to animation finished
			sprite.animation_finished.connect(_on_animation_finished)
	
	# Start the cycle
	timer.start()
	print("Cannon initialized and cycle started")

func _start_animation_sequence():
	print("Starting animation sequence")
	# Reset state
	is_beam_active = false
	beam_collision.set_deferred("disabled", true)
	current_lightning_index = 0
	beam_complete = false
	
	# Start sequential lightning
	_play_next_lightning()

func _play_next_lightning():
	if current_lightning_index >= sprites.size():
		# All lightning complete, play beam
		_play_beam_animations()
		return
	
	print("Playing lightning on sprite " + str(current_lightning_index))
	# Hide all sprites
	for sprite in sprites:
		if sprite:
			sprite.visible = false
	
	# Show and animate current sprite
	var current_sprite = sprites[current_lightning_index]
	if current_sprite:
		current_sprite.visible = true
		current_sprite.play("lightning")
		# Next sprite will be triggered by animation_finished signal
	else:
		# Skip broken sprite
		current_lightning_index += 1
		_play_next_lightning()

func _on_animation_finished(anim_name):
	if anim_name == "lightning" and not beam_complete:
		print("Lightning animation finished")
		# Move to next lightning
		current_lightning_index += 1
		# Wait a short delay before next
		await get_tree().create_timer(lightning_delay).timeout
		_play_next_lightning()

func _play_beam_animations():
	print("Starting beam animations on all sprites")
	beam_complete = true
	
	# Show all sprites
	for sprite in sprites:
		if sprite:
			sprite.visible = true
			sprite.frame = 0  # Reset to first frame
	
	# Play beam animation on all sprites 
	for sprite in sprites:
		if sprite:
			sprite.play("beam")
	
	# Enable collision and effects
	print("Enabling collision area")
	is_beam_active = true
	beam_collision.set_deferred("disabled", false)
	
	# Create light effect
	var tween = get_tree().create_tween()
	tween.tween_property(beam_light, "energy", 0, 0.2).from(2.5)
	
	# Start timer to end beam
	damage_timer.start()

func _end_beam():
	print("Ending beam")
	# Disable beam
	is_beam_active = false
	beam_collision.set_deferred("disabled", true)
	
	# Start delay before next cycle
	cycle_timer.start()

func _restart_cycle():
	print("Restarting cycle")
	# Hide all sprites
	for sprite in sprites:
		if sprite:
			sprite.visible = false
	
	# Start the next cycle
	timer.start()

func _on_area_2d_body_entered(body):
	print("Body entered beam: " + str(body.name))
	
	# Check if beam is active
	if not is_beam_active:
		return
		
	print("DEAD - Cannon hit player")
	# Try to respawn player
	if respawn_manager and respawn_manager.has_method("respawn_player"):
		respawn_manager.respawn_player(body)
	elif body.has_method("take_damage"):
		body.take_damage()
