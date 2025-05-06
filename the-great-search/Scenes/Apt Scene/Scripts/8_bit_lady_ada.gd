extends CharacterBody2D

# Movement parameters
@export var speed: float = 150.0
@export var acceleration: float = 500.0
@export var friction: float = 500.0

# Character components
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Movement direction tracking
var last_direction = Vector2.DOWN

func _physics_process(delta):
	# Get input direction
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Handle acceleration and deceleration
	if input_direction != Vector2.ZERO:
		velocity = velocity.move_toward(input_direction * speed, acceleration * delta)
		last_direction = input_direction
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Move the character
	move_and_slide()
	
	# Update animations
	update_animation(input_direction)

func update_animation(input_direction):
	if input_direction == Vector2.ZERO:
		# Handle idle animations based on last direction
		if last_direction.y > 0:
			animated_sprite_2d.play("idle")
		elif last_direction.y < 0:
			animated_sprite_2d.play("back_idle")
		elif last_direction.x != 0:
			animated_sprite_2d.play("left_idle")
			# Flip sprite horizontally based on direction
			animated_sprite_2d.flip_h = last_direction.x > 0
	else:
		# Handle walking animations
		if abs(input_direction.x) > abs(input_direction.y):
			# Horizontal movement takes priority
			animated_sprite_2d.play("walk_left")
			animated_sprite_2d.flip_h = input_direction.x > 0
		else:
			# Vertical movement
			if input_direction.y > 0:
				animated_sprite_2d.play("walk_down")
				animated_sprite_2d.flip_h = false
			else:
				animated_sprite_2d.play("walk_up")
				animated_sprite_2d.flip_h = false
