extends CharacterBody2D

class_name FlyingEnemy

# Enemy properties
@export var float_speed: float = 40.0
@export var chase_speed: float = 150.0
@export var detection_radius: float = 200.0
@export var float_radius: float = 50.0
@export var float_frequency: float = 1.5

# Internal variables
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape

var value: int = 1

var detection_area: Area2D
var hit_box: Area2D
var player_detected: bool = false
var player_ref: CharacterBody2D = null
var is_dying: bool = false
var float_timer: float = 0.0
var home_position: Vector2

func _ready() -> void:
	add_to_group("enemy")
	
	# Set home position to current position
	home_position = global_position
	
	# Setup detection area if it doesn't exist
	if has_node("DetectionArea"):
		detection_area = $DetectionArea
	else:
		detection_area = Area2D.new()
		detection_area.name = "DetectionArea"
		add_child(detection_area)
		
		# Create the collision shape for detection
		var detection_collision = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = detection_radius
		detection_collision.shape = circle_shape
		detection_area.add_child(detection_collision)
	
	# Setup hitbox if it doesn't exist
	if has_node("HitBox"):
		hit_box = $HitBox
	else:
		hit_box = Area2D.new()
		hit_box.name = "HitBox"
		add_child(hit_box)
		
		# Create collision shape for hitbox
		var hitbox_collision = CollisionShape2D.new()
		var capsule = CapsuleShape2D.new()
		capsule.radius = 10.0
		capsule.height = 20.0
		hitbox_collision.shape = capsule
		hit_box.add_child(hitbox_collision)
	
	# Make sure the collision layers are set properly
	detection_area.collision_layer = 0  # Not collidable
	detection_area.collision_mask = 1   # Detect player (assuming player is on layer 1)
	
	# Connect signals with error checking
	if !detection_area.body_entered.is_connected(_on_detection_area_body_entered):
		detection_area.body_entered.connect(_on_detection_area_body_entered)
	
	if !detection_area.body_exited.is_connected(_on_detection_area_body_exited):
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	if !hit_box.body_entered.is_connected(_on_hit_box_body_entered):
		hit_box.body_entered.connect(_on_hit_box_body_entered)

func _physics_process(delta: float) -> void:
	if is_dying:
		return
	
	# Debug visualization for detection radius
	# queue_redraw() # Uncomment this if you add _draw() function
	
	if player_detected and player_ref != null:
		chase_player(delta)
	else:
		float_around(delta)
	
	# Handle animations
	update_animation()
	
	move_and_slide()

# Uncomment if you want to see the detection radius
# func _draw() -> void:
#	draw_circle(Vector2.ZERO, detection_radius, Color(1, 0, 0, 0.2))

func float_around(delta: float) -> void:
	float_timer += delta * float_frequency
	
	# Calculate a floating pattern using sine and cosine for smooth movement
	var offset_x = sin(float_timer) * float_radius
	var offset_y = cos(float_timer * 0.7) * (float_radius * 0.6)
	
	var target_position = home_position + Vector2(offset_x, offset_y)
	var direction = (target_position - global_position).normalized()
	
	velocity = direction * float_speed
	
	# Gradually return to home position if far away
	if global_position.distance_to(home_position) > float_radius * 1.5:
		var home_direction = (home_position - global_position).normalized()
		velocity += home_direction * (float_speed * 0.5)

func chase_player(delta: float) -> void:
	if player_ref == null:
		player_detected = false
		return
		
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * chase_speed
	
	# If player gets too far, return to floating but DON'T set player_ref to null
	if global_position.distance_to(player_ref.global_position) > detection_radius * 1.2:
		player_detected = false
		# Removed: player_ref = null

func update_animation() -> void:
	var is_moving_right = velocity.x > 0
	var is_moving_left = velocity.x < 0
	
	if is_moving_right:
		animated_sprite.flip_h = false
	elif is_moving_left:
		animated_sprite.flip_h = true
	
	if player_detected:
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")
		else:
			animated_sprite.play("idle")
	else:
		animated_sprite.play("idle")

func take_damage() -> void:
	die()




func die() -> void:
	is_dying = true
	velocity = Vector2.ZERO
	
	Global.sparkysVanquished += value
	print(Global.score)
	Global.update_score.emit()
	print("Global shouldve emitted")
	
	
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await animated_sprite.animation_finished
	
	# Disable collisions and monitoring
	collision_shape.set_deferred("disabled", true)
	hit_box.set_deferred("monitoring", false)
	detection_area.set_deferred("monitoring", false)
	
	queue_free()

func _on_detection_area_body_entered(body: Node2D) -> void:
	print("Body entered: ", body.name)  # Debug print
	if body.is_in_group("player"):
		print("Player detected!")  # Debug print
		player_detected = true
		player_ref = body

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_detected = false
		# Removed: player_ref = null

func _on_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Damage the player
		if body.has_method("take_damage"):
			body.take_damage()
