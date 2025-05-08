extends Node2D

# Nodes
@onready var beam_holder = $Position2D
@onready var timer = $Timer
@onready var beam_collision = $Area2D/CollisionShape2D
@onready var beam_light = $Light2D
@onready var damage_timer = $damageTimer
@onready var cycle_timer = $CycleDelayTimer

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

func _ready():
	# Setup timers
	timer.wait_time = cycle_time
	damage_timer.wait_time = beam_duration
	
	# Connect signals
	timer.timeout.connect(_start_animation_sequence)
	damage_timer.timeout.connect(_end_beam)
	cycle_timer.timeout.connect(_restart_cycle)
	
	# Hide all sprites initially
	for sprite in sprites:
		if sprite:
			sprite.visible = false
	
	# Start the cycle
	timer.start()
	print("Cannon initialized and cycle started")

func _start_animation_sequence():
	print("Starting animation sequence")
	# Reset state
	is_beam_active = false
	beam_collision.disabled = true
	
	# Start sequential lightning
	_play_lightning_sequence(0)

func _play_lightning_sequence(index):
	# If we've shown all lightning animations, start the beam
	if index >= sprites.size():
		_start_beam()
		return
	
	print("Playing lightning on sprite " + str(index))
	# Hide all sprites
	for sprite in sprites:
		if sprite:
			sprite.visible = false
	
	# Show and animate current sprite
	var current_sprite = sprites[index]
	if current_sprite:
		current_sprite.visible = true
		current_sprite.play("lightning")
		
		# Schedule next lightning after delay
		var total_time = lightning_duration + lightning_delay
		get_tree().create_timer(total_time).timeout.connect(
			func(): _play_lightning_sequence(index + 1)
		)

func _start_beam():
	print("Starting beam")
	# Show all sprites and play beam animation
	for sprite in sprites:
		if sprite:
			sprite.visible = true
			sprite.play("beam")
	
	# Enable effects
	is_beam_active = true
	beam_collision.disabled = false
	
	# Create light effect
	var tween = get_tree().create_tween()
	tween.tween_property(beam_light, "energy", 0, 0.2).from(2.5)
	
	# Start timer to end beam
	damage_timer.start()

func _end_beam():
	print("Ending beam")
	# Disable beam
	is_beam_active = false
	beam_collision.disabled = true
	
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

# Handle collisions
func _on_area_2d_body_entered(body):
	print("Body entered beam: " + str(body.name))
	if body.has_method("take_damage"):
		body.take_damage()
