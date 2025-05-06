extends CharacterBody2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var kill_timer: Timer = $KillTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var interaction_area: InteractionArea = $InteractionArea

const lines: Array[String] = [
	"Hey There!"
]

@onready var dash_duration_timer: Timer = $DashDurationTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var dash_particles: GPUParticles2D = $DashParticles

@onready var attack_hitbox: Area2D = $AttackHitbox
var enemies_hit = []

# Acceleration and deceleration parameters
const ACCELERATION = 2200.0
const DECELERATION = 3000.0
const AIR_ACCELERATION = 1400.0
const AIR_DECELERATION = 1000.0

var is_attacking = false
var attack_loop_playing = false
@export var attack_button = "attack"  # Configure in Project Settings > Input Map
@onready var attack_timer: Timer = $Attack


const DASH_SPEED = 750.0
const DASH_DURATION = 0.25
const DASH_COOLDOWN = 0.6

# Dash state
var can_dash = true
var is_dashing = false
var dash_direction = Vector2.ZERO

const SPEED = 325.0
const JUMP_VELOCITY = -400.0
const WALL_SLIDE_SPEED = 100.0
const SLOW_TIME_SCALE = 0.5

var last_wall_normal = Vector2.ZERO
var wall_jump_cooldown_timer = 0.0
const WALL_JUMP_COOLDOWN = 0.1

var has_double_jump = false
var bounce_jump_available = false

# Wall jump configuration
const WALL_KICK_ANGLE = 60.0  
var input_pause_after_wall_jump = 0.1


#Gravity
var gravity = 1300         
var wall_jump_direction = 2
var time_slowed = false
var movement_input_monitoring = Vector2(true, true)  


#For Jump Item State
var used_jump = false  # Tracks if player has used their jump
var bounced_recently = false # Tracks if player bounced recently off a jump item
var bounce_grace_time = 0.1  # Time in seconds where bounce detection remains active

#Jump Buffer Time
var jump_buffer_time = 0.15  # Time in seconds to buffer a jump input
var jump_buffer_timer = 0.0

#Coyote Time
var coyote_time = 0.2  # Adjustable window (0.1s is a good starting point)
var coyote_timer = 0.0
var was_on_floor = false


func _ready() -> void:
	Engine.time_scale = 1.0 
	interaction_area.interact = Callable(self, "_on_interact")
	add_to_group("player")
	jump_buffer_timer = 0.0
	
	if has_node("AttackTimer"):
		attack_timer = $AttackTimer
		attack_timer.timeout.connect(start_attack_loop)
	else:
		var timer = Timer.new()
		timer.name = "AttackTimer"
		timer.one_shot = true
		timer.wait_time = 0.3
		timer.timeout.connect(start_attack_loop)
		add_child(timer)
		attack_timer = timer
		
	if has_node("AttackHitbox"):
		attack_hitbox = $AttackHitbox
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = true
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
		attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	
	if has_node("DashDurationTimer"):
		dash_duration_timer = $DashDurationTimer
		dash_duration_timer.timeout.connect(end_dash)
	else:
		var duration_timer = Timer.new()
		duration_timer.name = "DashDurationTimer"
		duration_timer.one_shot = true
		duration_timer.wait_time = DASH_DURATION
		duration_timer.timeout.connect(end_dash)
		add_child(duration_timer)
		dash_duration_timer = duration_timer
		
	if has_node("DashCooldownTimer"):
		dash_cooldown_timer = $DashCooldownTimer
		dash_cooldown_timer.timeout.connect(reset_dash)
		
	else:
		var cooldown_timer = Timer.new()
		cooldown_timer.name = "DashCooldownTimer"
		cooldown_timer.one_shot = true
		cooldown_timer.wait_time = DASH_COOLDOWN
		cooldown_timer.timeout.connect(reset_dash)
		add_child(cooldown_timer)
		dash_cooldown_timer = cooldown_timer


func perform_dash():
	if is_dashing:
		return
		
	is_dashing = true
	can_dash = false
	
	var input_direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
		)
		
	if input_direction.length() > 0.1:
		dash_direction = input_direction.normalized()
	else:
		dash_direction = Vector2(-1 if animated_sprite.flip_h else 1, 0)
		
	dash_duration_timer.start(DASH_DURATION)
	has_double_jump = true
	
func end_dash():
	if !is_dashing:
		return
		
	is_dashing = false
	velocity = Vector2.ZERO
	dash_cooldown_timer.start(DASH_COOLDOWN)


func reset_dash():
	can_dash = true

func _on_interact():
	DialogManager.start_dialog(global_position, lines)
	await DialogManager.dialog_finished
	

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("slow_time"):
		toggle_time_slow()
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	var direction := Input.get_axis("move_left", "move_right")
	

	if Input.is_action_just_pressed(attack_button) and !is_attacking:
		start_attack()
	elif !Input.is_action_pressed(attack_button) and attack_loop_playing:
		end_attack()
	
	if Input.is_action_just_pressed("dash") and can_dash and !is_dashing:
		perform_dash()

	if is_dashing:
		velocity = dash_direction * DASH_SPEED
		animated_sprite.play("dash")  # Add a dash animation
		move_and_slide()
		return
	
	# Wall check
	var is_on_wall_state = is_on_wall() and not is_on_floor()
	
	if wall_jump_cooldown_timer > 0:
		wall_jump_cooldown_timer -= delta
			
	if is_on_wall_state:
		var current_wall_normal = get_wall_normal()
		
		if current_wall_normal != last_wall_normal and not current_wall_normal.is_zero_approx():
			last_wall_normal = current_wall_normal
	else:
		if is_on_floor():
			last_wall_normal = Vector2.ZERO

	# Coyote time handling
	if is_on_floor():
		has_double_jump = true  # Reset double jump when on floor
		was_on_floor = true
		coyote_timer = coyote_time
	elif was_on_floor:
		coyote_timer -= delta
		if coyote_timer <= 0:
			was_on_floor = false
			
			
	if not is_on_floor():
		if is_on_wall_state and direction != 0:
			# Improved wall slide with reduced gravity factor
			velocity.y = min(velocity.y + gravity * delta * 0.5, WALL_SLIDE_SPEED)
			wall_jump_direction = 1 if direction > 0 else -1
		else:
			if is_attacking:
				velocity.y += gravity * delta * 0.3
			else:
				velocity.y += gravity * delta
			
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or (was_on_floor and coyote_timer > 0):
			audio_stream_player_2d.play()
			velocity.y = JUMP_VELOCITY
			was_on_floor = false
			coyote_timer = 0
		elif is_on_wall_state and wall_jump_cooldown_timer <= 0:
			# Infinite wall jumps - removed can_wall_jump condition
			wall_jump()
			wall_jump_cooldown_timer = WALL_JUMP_COOLDOWN
			
		elif bounce_jump_available:
			audio_stream_player_2d.play()
			velocity.y = JUMP_VELOCITY
			bounce_jump_available = false
			
		elif has_double_jump:
			# Regular double jump if available
			audio_stream_player_2d.play()
			velocity.y = JUMP_VELOCITY
			has_double_jump = false
			
		else:
			jump_buffer_timer = jump_buffer_time
	
	# Handle movement with acceleration and deceleration
	if movement_input_monitoring == Vector2(true, true):
		if direction != 0:
			# Apply acceleration based on whether player is on ground or in air
			var current_acceleration = ACCELERATION if is_on_floor() else AIR_ACCELERATION
			velocity.x = move_toward(velocity.x, direction * SPEED, current_acceleration * delta)
		else:
			# Apply deceleration based on whether player is on ground or in air
			var current_deceleration = DECELERATION if is_on_floor() else AIR_DECELERATION
			velocity.x = move_toward(velocity.x, 0, current_deceleration * delta)
	
	# Sprite direction
	if is_on_wall_state:
		animated_sprite.flip_h = last_wall_normal.x > 0
	else:
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true
			
			
	if is_attacking:
		if attack_loop_playing:
			animated_sprite.play("attack_loop")
		else:
			animated_sprite.play("attack_initial")
	else:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
		else:
			if is_on_wall_state:
				animated_sprite.play("wall_latch")
			elif velocity.y < 0:
				animated_sprite.play("jump")
			else:
				animated_sprite.play("falling")
	
	move_and_slide()
	
	if is_on_floor() and jump_buffer_timer > 0:
		audio_stream_player_2d.play()
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
	
	
	if is_on_wall():
		var current_wall_normal = get_wall_normal()
		
		if current_wall_normal != last_wall_normal and not current_wall_normal.is_zero_approx():
			last_wall_normal = current_wall_normal


func handle_bounce():
	bounce_jump_available = true

func wall_jump():
	var horizontal_wall_kick = abs(JUMP_VELOCITY * cos(WALL_KICK_ANGLE * (PI / 180)))
	var vertical_wall_kick = abs(JUMP_VELOCITY * sin(WALL_KICK_ANGLE * (PI / 180)))
	
	velocity.y = -vertical_wall_kick
	velocity.x = -horizontal_wall_kick if wall_jump_direction > 0 else horizontal_wall_kick
	
	# Shorter input pause for better control
	movement_input_monitoring = Vector2(false, false)
	input_pause_reset(input_pause_after_wall_jump * 0.7) # Reduced pause time

func input_pause_reset(time):
	await get_tree().create_timer(time).timeout
	movement_input_monitoring = Vector2(true, true)

func toggle_time_slow() -> void:
	time_slowed = !time_slowed
	Engine.time_scale = SLOW_TIME_SCALE if time_slowed else 1.0
	
func start_attack_loop():
	if is_attacking:
		attack_loop_playing = true
		animated_sprite.play("attack_loop")
		
func end_attack():
	is_attacking = false
	attack_loop_playing = false
	attack_timer.stop()
	attack_hitbox.monitoring = false
	
	
func start_attack():
	is_attacking = true
	attack_loop_playing = false
	animated_sprite.play("attack_initial")
	attack_timer.start()
	
	attack_hitbox.monitoring = true
	enemies_hit.clear()
	
	
func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	
	if body.is_in_group("enemy") and body not in enemies_hit:
		if body.has_method("take_damage"):
			body.take_damage()
			enemies_hit.append(body)
			
func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	
	var parent = area.get_parent()
	if parent.is_in_group("enemy") and parent not in enemies_hit:
		if parent.has_method("take_damage"):
			parent.take_damage()
			enemies_hit.append(parent)
