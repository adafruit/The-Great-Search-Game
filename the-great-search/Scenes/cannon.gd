extends Node2D

@onready var beamHolder: Marker2D = $Position2D
@onready var timer: Timer = $Timer
@onready var beamCollision: CollisionShape2D = $Area2D/CollisionShape2D
@onready var beamLight: PointLight2D = $Light2D
@onready var startDelay: Timer = $startDelay
@onready var damageTimer: Timer = $damageTimer
@onready var lightningTimer: Timer = $lightningTimer
@onready var death_timer: Timer = $deathTimer
@onready var cycleDelayTimer: Timer = $CycleDelayTimer

@onready var area_2d: Area2D = $Area2D
@onready var particles: GPUParticles2D = $GPUParticles2D

@export var distance: float = 300
@export var timerLength: float = 0.5
@export var beginDelay: float = 0.5
@export var damage: float = 10.0
@export var beam_color: Color = Color(0.5, 0.8, 1.0, 1.0)
@export var screen_shake_intensity: float = 5.0
@export var branch_chance: float = 0.3
@export var cyclePauseTime: float = 0.5

# Animation timing parameters
@export var lightning_travel_delay: float = 0.15  # Delay between each lightning sprite animation
@export var beam_start_delay: float = 0.3        # Delay between last lightning and beam start

@onready var animated_sprite_2d: AnimatedSprite2D = $Position2D/AnimatedSprite2D
@onready var animated_sprite_2d_2: AnimatedSprite2D = $Position2D/AnimatedSprite2D2
@onready var animated_sprite_2d_4: AnimatedSprite2D = $Position2D/AnimatedSprite2D4
@onready var animated_sprite_2d_3: AnimatedSprite2D = $Position2D/AnimatedSprite2D3
@onready var animated_sprite_2d_5: AnimatedSprite2D = $Position2D/AnimatedSprite2D5
@onready var animated_sprite_2d_6: AnimatedSprite2D = $Position2D/AnimatedSprite2D6
@onready var animated_sprite_2d_7: AnimatedSprite2D = $Position2D/AnimatedSprite2D7
@onready var animated_sprite_2d_8: AnimatedSprite2D = $Position2D/AnimatedSprite2D8

@onready var respawn_manager = get_node("/root/RespawnGlobal")

var is_beam_active: bool = false
var bodies_in_area: Array = []
var current_sprite_index: int = 0
var all_sprites: Array = []

func _ready() -> void:
	# Set up timers
	timer.wait_time = timerLength
	damageTimer.wait_time = 0.2
	
	# Connect signals
	timer.timeout.connect(_on_timer_timeout)
	startDelay.timeout.connect(_on_start_delay_timeout)
	lightningTimer.timeout.connect(_on_lightning_timer_timeout)
	damageTimer.timeout.connect(_on_damage_timer_timeout)
	cycleDelayTimer.timeout.connect(_on_cycle_delay_timer_timeout)
	death_timer.timeout.connect(_on_death_timer_timeout)
	
	# Initialize the sprite array in order of animation
	all_sprites = get_sprites()
	
	# Ensure animations don't loop
	for sprite in all_sprites:
		if sprite.sprite_frames != null:
			sprite.sprite_frames.set_animation_loop("lightning", false)
			sprite.sprite_frames.set_animation_loop("beam", false)
		
		# Initially hide all sprites
		sprite.visible = false
		
		# Connect animation finished signal
		sprite.animation_finished.connect(_on_animation_finished.bind(sprite))
	
	# Start the animation cycle
	if beginDelay == 0:
		timer.start()
	else:
		startDelay.wait_time = beginDelay
		startDelay.start()

func get_sprites() -> Array:
	return [
		animated_sprite_2d,     # Index 0
		animated_sprite_2d_2,   # Index 1
		animated_sprite_2d_4,   # Index 2
		animated_sprite_2d_3,   # Index 3
		animated_sprite_2d_5,   # Index 4
		animated_sprite_2d_6,   # Index 5
		animated_sprite_2d_8,   # Index 6
		animated_sprite_2d_7    # Index 7
	]

func _on_timer_timeout() -> void:
	self.modulate = Color(1,1,1,1)
	
	# Reset the sequence
	reset_all_sprites()
	current_sprite_index = 0
	
	# Start the first lightning animation
	play_next_lightning_animation()

func reset_all_sprites() -> void:
	for sprite in all_sprites:
		sprite.stop()
		sprite.frame = 0
		sprite.visible = false
	
	# Make sure beam is disabled
	beamCollision.set_deferred("disabled", true)
	is_beam_active = false
	particles.emitting = false

func play_next_lightning_animation() -> void:
	if current_sprite_index < all_sprites.size():
		var current_sprite = all_sprites[current_sprite_index]
		
		# Make only this sprite visible
		for i in range(all_sprites.size()):
			all_sprites[i].visible = (i == current_sprite_index)
		
		# Play the lightning animation on this sprite
		current_sprite.play("lightning")
		
		# The next sprite will be triggered by the animation_finished signal
	else:
		# All lightning animations are complete, prepare for beam
		await get_tree().create_timer(beam_start_delay).timeout
		start_beam_animations()

func _on_animation_finished(anim_name: String, sprite: AnimatedSprite2D) -> void:
	if anim_name == "lightning":
		# This sprite's lightning animation is done
		if sprite == all_sprites[current_sprite_index]:
			# Time to move to the next sprite
			current_sprite_index += 1
			
			# Wait for a small delay before showing the next lightning
			await get_tree().create_timer(lightning_travel_delay).timeout
			play_next_lightning_animation()

func start_beam_animations() -> void:
	# Make all sprites visible and play beam animation
	for sprite in all_sprites:
		sprite.visible = true
		sprite.frame = 0  # Reset to first frame
		sprite.play("beam")
	
	# Enable the beam collision and effects
	beamCollision.set_deferred("disabled", false)
	particles.emitting = true
	is_beam_active = true
	
	# Create light effect
	var tween = get_tree().create_tween()
	tween.tween_property(beamLight, "energy", 0, 0.2).from(2.5)
	
	# Start damage timer to time when the beam will turn off
	damageTimer.start()

func _on_start_delay_timeout() -> void:
	timer.start()

func _on_lightning_timer_timeout() -> void:
	# This timer is now unused since we're using animation_finished signal
	pass

func _on_damage_timer_timeout() -> void:
	# Turn off the beam after damage timer ends
	beamCollision.set_deferred("disabled", true)
	is_beam_active = false
	
	# Add a delay before starting the next cycle
	cycleDelayTimer.start()

func _on_cycle_delay_timer_timeout() -> void:
	# Start the entire sequence again
	timer.start()

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("DEAD - Cannon")
	respawn_player(body)
	
func _on_area_2d_body_exited(body: Node2D) -> void:
	# Remove this body from our tracking array
	if bodies_in_area.has(body):
		bodies_in_area.erase(body)

func respawn_player(player: Node2D):
	respawn_manager.respawn_player(player)

func check_bodies_in_beam() -> void:
	if is_beam_active and not bodies_in_area.is_empty():
		if death_timer.time_left == 0:
			print("DEAD")
			Engine.time_scale = 0.4
			death_timer.start()
	elif not is_beam_active and death_timer.time_left > 0:
		death_timer.stop()
		Engine.time_scale = 1

func _on_death_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
