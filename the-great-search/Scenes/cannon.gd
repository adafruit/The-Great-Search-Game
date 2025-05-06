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

# Lightning travel effect timing controls
@export var lightning_travel_delay: float = 0.5  # Delay between showing each lightning sprite
@export var lightning_duration: float = 0.7      # How long each lightning animation is visible

@onready var animated_sprite_2d: AnimatedSprite2D = $Position2D/AnimatedSprite2D
@onready var animated_sprite_2d_2: AnimatedSprite2D = $Position2D/AnimatedSprite2D2
@onready var animated_sprite_2d_3: AnimatedSprite2D = $Position2D/AnimatedSprite2D3
@onready var animated_sprite_2d_4: AnimatedSprite2D = $Position2D/AnimatedSprite2D4
@onready var animated_sprite_2d_5: AnimatedSprite2D = $Position2D/AnimatedSprite2D5
@onready var animated_sprite_2d_6: AnimatedSprite2D = $Position2D/AnimatedSprite2D6
@onready var animated_sprite_2d_7: AnimatedSprite2D = $Position2D/AnimatedSprite2D7
@onready var animated_sprite_2d_8: AnimatedSprite2D = $Position2D/AnimatedSprite2D8

@onready var respawn_manager = get_node("/root/RespawnGlobal")

var is_beam_active: bool = false
var bodies_in_area: Array = []
var lightning_index: int = 0
var lightning_travel_timer: Timer
var lightning_duration_timer: Timer

func _ready() -> void:
	timer.wait_time = timerLength
	
	# Create and setup the lightning travel timer
	lightning_travel_timer = Timer.new()
	lightning_travel_timer.name = "LightningTravelTimer"
	lightning_travel_timer.one_shot = true
	lightning_travel_timer.wait_time = lightning_travel_delay
	add_child(lightning_travel_timer)
	lightning_travel_timer.timeout.connect(_on_lightning_travel_timer_timeout)
	
	# Create and setup the lightning duration timer
	lightning_duration_timer = Timer.new()
	lightning_duration_timer.name = "LightningDurationTimer"
	lightning_duration_timer.one_shot = true
	lightning_duration_timer.wait_time = lightning_duration
	add_child(lightning_duration_timer)
	lightning_duration_timer.timeout.connect(_on_lightning_duration_timer_timeout)
	
	if not has_node("CycleDelayTimer"):
		cycleDelayTimer = Timer.new()
		cycleDelayTimer.name = "CycleDelayTimer"
		cycleDelayTimer.one_shot = true
		add_child(cycleDelayTimer)
	
	cycleDelayTimer.wait_time = cyclePauseTime
	
	timer.timeout.connect(_on_timer_timeout)
	startDelay.timeout.connect(_on_start_delay_timeout)
	lightningTimer.timeout.connect(_on_lightning_timer_timeout)
	damageTimer.timeout.connect(_on_damage_timer_timeout)
	cycleDelayTimer.timeout.connect(_on_cycle_delay_timer_timeout)
	death_timer.timeout.connect(_on_death_timer_timeout)
	
	# Ensure animations don't loop (if they do, they won't stop properly)
	var sprites = get_sprites()
	for sprite in sprites:
		if sprite.sprite_frames != null:
			for anim in sprite.sprite_frames.get_animation_names():
				sprite.sprite_frames.set_animation_loop(anim, false)
		
		# Initially hide all sprites
		sprite.visible = false
	
	if beginDelay == 0:
		timer.start()
	else:
		startDelay.wait_time = beginDelay
		startDelay.start()

func start_animation_cycle() -> void:
	timer.start()

func _on_timer_timeout() -> void:
	self.modulate = Color(1,1,1,1)
	
	# Reset and hide all sprites initially
	reset_all_sprites()
	
	# Start the sequential lightning animation
	lightning_index = 0
	start_lightning_sequence()

func get_sprites() -> Array:
	return [
		animated_sprite_2d,
		animated_sprite_2d_2, 
		animated_sprite_2d_3,
		animated_sprite_2d_4,
		animated_sprite_2d_5,
		animated_sprite_2d_6,
		animated_sprite_2d_7,
		animated_sprite_2d_8
	]

func reset_all_sprites() -> void:
	var sprites = get_sprites()
	for sprite in sprites:
		sprite.stop()
		sprite.frame = 0
		sprite.visible = false

func start_lightning_sequence() -> void:
	var sprites = get_sprites()
	
	if lightning_index < sprites.size():
		# Make sure all other sprites are hidden
		for i in range(sprites.size()):
			sprites[i].visible = i == lightning_index
		
		# Play lightning animation on the current sprite
		sprites[lightning_index].frame = 0  # Reset to first frame
		sprites[lightning_index].play("lightning")
		
		# Wait for the duration timer before moving to the next sprite
		lightning_duration_timer.start()
	else:
		# All lightning animations complete, now show the beam
		lightningTimer.start()

func _on_lightning_duration_timer_timeout() -> void:
	# Move to the next lightning in sequence after this one has been visible for a while
	lightning_index += 1
	# Start the travel delay before showing the next sprite
	lightning_travel_timer.start()

func _on_lightning_travel_timer_timeout() -> void:
	# Time to show the next sprite in sequence
	start_lightning_sequence()

func _on_start_delay_timeout() -> void:
	timer.start()

func _on_lightning_timer_timeout() -> void:
	self.modulate = Color(1,1,1,1)
	
	# Now make ALL sprites visible and play beam animation on all of them
	var sprites = get_sprites()
	for sprite in sprites:
		sprite.visible = true
		sprite.frame = 0  # Reset to first frame
		sprite.play("beam")
	
	beamCollision.set_deferred("disabled", false)
	particles.emitting = true
	is_beam_active = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(beamLight, "energy", 0, 0.2).from(2.5)
	
	damageTimer.start()

func _on_damage_timer_timeout() -> void:
	beamCollision.set_deferred("disabled", true)  # Disable the collision when damage timer ends
	is_beam_active = false
	cycleDelayTimer.start()

func _on_cycle_delay_timer_timeout() -> void:
	timer.start()  # Restart the entire sequence after delay

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("DEAD - Cannon")
	respawn_player(body)
	
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
