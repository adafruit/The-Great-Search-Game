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


var is_beam_active: bool = false

var bodies_in_area: Array = []

func _ready() -> void:
#	beamSound.max_distance = distance
	timer.wait_time = timerLength
	
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
	
	#area_2d.body_entered.connect(_on_area_2d_body_entered)
	#area_2d.body_exited.connect(_on_area_2d_body_exited)
	
	if beginDelay == 0:
		timer.start()
	else:
		startDelay.wait_time = beginDelay
		startDelay.start()
		
	
func start_animation_cycle() -> void:
	# First, play lightning animatio
	timer.start()

func _on_timer_timeout() -> void:
	self.modulate = Color(1,1,1,1)
	var beams = beamHolder.get_children()
	for l in beams:
		l.play("lightning")
		
	lightningTimer.start()


func _on_start_delay_timeout() -> void:
	timer.start()


func _on_lightning_timer_timeout() -> void:
	
	var beams = beamHolder.get_children()
	self.modulate = Color(1,1,1,1)
	
	# Restore sound
	#beamSound.pitch_scale = randf_range(0.8, 1.2)
	#beamSound.play()
	
	beamCollision.set_deferred("disabled", false)
	
	# Emit particles at impact point
	particles.emitting = true
	
	for b in beams:
		b.play("beam")
		
		# Add branching lightning with chance
		#if randf() < branch_chance:
			#create_branch_lightning(b.global_position)
	var tween = get_tree().create_tween()
	tween.tween_property(beamLight, "energy", 0, 0.2).from(2.5)
	
	# Enhanced light effect with flickering
	#var tween = create_flicker_effect()
	
	damageTimer.start()

func _on_damage_timer_timeout() -> void:
	beamCollision.set_deferred("disabled", true)
	
	cycleDelayTimer.start()


func _on_cycle_delay_timer_timeout() -> void:
	timer.start()


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("DEAD")
	



func check_bodies_in_beam() -> void:
	# If we're in beam phase and have bodies in the area, start death timer
	if is_beam_active and not bodies_in_area.is_empty():
		if death_timer.time_left == 0:  # Only start if not already running
			print("DEAD")
			Engine.time_scale = 0.4
			death_timer.start()
	elif not is_beam_active and death_timer.time_left > 0:
		death_timer.stop()
		Engine.time_scale = 1


func _on_death_timer_timeout() -> void:
	Engine.time_scale = 1
	get_tree().reload_current_scene()
