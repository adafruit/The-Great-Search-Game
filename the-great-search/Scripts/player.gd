extends CharacterBody2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var kill_timer: Timer = $KillTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const WALL_SLIDE_SPEED = 100.0
const SLOW_TIME_SCALE = 0.5

var last_wall_normal = Vector2.ZERO
var can_wall_jump = true
var wall_jump_cooldown_timer = 0.0
const WALL_JUMP_COOLDOWN = 0.5

var has_double_jump = false
var bounce_jump_available = false

# Wall jump configuration
const WALL_KICK_ANGLE = 60.0  
var input_pause_after_wall_jump = 0.1


#Gravity
var gravity = 1200         
var wall_jump_direction = 1
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
var coyote_time = 0.1  # Adjustable window (0.1s is a good starting point)
var coyote_timer = 0.0
var was_on_floor = false


func _ready() -> void:
	Engine.time_scale = 1.0 
	add_to_group("player")
	jump_buffer_timer = 0.0 

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("slow_time"):
		toggle_time_slow()
	
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	var direction := Input.get_axis("move_left", "move_right")
	
	# Wall check
	var is_on_wall_state = is_on_wall() and not is_on_floor()
	
	if wall_jump_cooldown_timer > 0:
			wall_jump_cooldown_timer -= delta
			
	if is_on_wall_state:
		var current_wall_normal = get_wall_normal()
		
		if current_wall_normal != last_wall_normal and not current_wall_normal.is_zero_approx():
			can_wall_jump = true
			last_wall_normal = current_wall_normal
	else:
		if is_on_floor():
			can_wall_jump = true
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
			velocity.y = min(velocity.y + gravity * delta, WALL_SLIDE_SPEED)
			wall_jump_direction = 1 if direction > 0 else -1
		else:
			velocity.y += gravity * delta
			
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or (was_on_floor and coyote_timer > 0):
			audio_stream_player_2d.play()
			velocity.y = JUMP_VELOCITY
			was_on_floor = false
			coyote_timer = 0
		elif is_on_wall_state and can_wall_jump and wall_jump_cooldown_timer <= 0:
			wall_jump()
			can_wall_jump = false
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
	
	# Handle movement based on input monitoring
	if direction and movement_input_monitoring == Vector2(true, true):
		velocity.x = direction * SPEED
	elif movement_input_monitoring == Vector2(true, true):
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Sprite direction
	if is_on_wall_state:
		animated_sprite.flip_h = wall_jump_direction < 0
	else:
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true
	
	# Animations
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
			can_wall_jump = true
			last_wall_normal = current_wall_normal
			
		else:
			if is_on_floor():
				can_wall_jump = true
				last_wall_normal = Vector2.ZERO


func handle_bounce():
	bounce_jump_available = true

func wall_jump():
	var horizontal_wall_kick = abs(JUMP_VELOCITY * cos(WALL_KICK_ANGLE * (PI / 180)))
	var vertical_wall_kick = abs(JUMP_VELOCITY * sin(WALL_KICK_ANGLE * (PI / 180)))
	
	velocity.y = -vertical_wall_kick
	velocity.x = -horizontal_wall_kick if wall_jump_direction > 0 else horizontal_wall_kick
	

	movement_input_monitoring = Vector2(false, false)
	input_pause_reset(input_pause_after_wall_jump)

func input_pause_reset(time):
	await get_tree().create_timer(time).timeout
	movement_input_monitoring = Vector2(true, true)

func toggle_time_slow() -> void:
	time_slowed = !time_slowed
	Engine.time_scale = SLOW_TIME_SCALE if time_slowed else 1.0
	
