extends CharacterBody2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var kill_timer: Timer = $KillTimer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
const SPEED = 190.0
const JUMP_VELOCITY = -400.0
const WALL_SLIDE_SPEED = 100.0
const SLOW_TIME_SCALE = 0.5

# Wall jump configuration
const WALL_KICK_ANGLE = 60.0  
var input_pause_after_wall_jump = 0.1

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var wall_jump_direction = 1
var time_slowed = false
var movement_input_monitoring = Vector2(true, true)  

func _ready() -> void:
	Engine.time_scale = 1.0 

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("slow_time"):
		toggle_time_slow()
	
	var direction := Input.get_axis("move_left", "move_right")
	
	# Wall check
	var is_on_wall_state = is_on_wall() and not is_on_floor()
	
	if not is_on_floor():
		if is_on_wall_state and direction != 0:
			velocity.y = min(velocity.y + gravity * delta, WALL_SLIDE_SPEED)
			wall_jump_direction = 1 if direction > 0 else -1
		else:
			velocity.y += gravity * delta
			
	if Input.is_action_just_pressed("jump"):
		
		if is_on_floor():
			audio_stream_player_2d.play()
			velocity.y = JUMP_VELOCITY
		elif is_on_wall_state:
			wall_jump()
	
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
