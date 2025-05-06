extends CharacterBody2D
class_name Enemy

@export var speed = 100.0
@export var patrol_distance = 50.0  # Reduced for shorter pacing
@export var gravity = 980.0

var start_position = Vector2.ZERO
var direction = Vector2.LEFT
var is_dead = false

@onready var sprite = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

func _ready():
	start_position = global_position
	
	# Start the walk animation if it exists
	if sprite != null:
		sprite.play("default")

func _physics_process(delta):
	if is_dead:
		return
		
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Handle patrol logic
	var distance_traveled = abs(global_position.x - start_position.x)
	
	# Change direction if reached patrol distance
	if distance_traveled >= patrol_distance:
		direction = -direction
		if sprite:
			# Flipping logic reversed
			sprite.flip_h = direction.x < 0
	
	# Set horizontal velocity based on direction
	velocity.x = direction.x * speed
	
	move_and_slide()

func take_damage():
	is_dead = true
	velocity = Vector2.ZERO
	
	if sprite != null and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		
		# Optional: Add a timer to free the enemy after death animation
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(queue_free)
	else:
		# If no death animation, just queue_free immediately
		queue_free()
