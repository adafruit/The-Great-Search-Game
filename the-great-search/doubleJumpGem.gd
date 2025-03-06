extends Node2D
@onready var collision_shape_2d: CollisionShape2D = $Area2D/CollisionShape2D
@onready var timer: Timer = $Timer
@onready var point_light_2d: PointLight2D = $PointLight2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


var can_bounce: bool = true
@export var jump_force: float = 400.0
@export var reset_time: float = 2.0

func _ready() -> void:
	timer.wait_time = reset_time
	# Connect to the animation_finished signal
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	# Check if we just finished the hit animation
	if animated_sprite_2d.animation == "hit":
		# Hide both the sprite and light
		hide_item()
		#start cooldown
		timer.start()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not can_bounce or not body.is_in_group("player"):
		return
		
	apply_bounce_to_player(body)
	can_bounce = false
	collision_shape_2d.set_deferred("disabled", true)
	var tween = get_tree().create_tween()
	tween.tween_property(point_light_2d, "energy", 0, 0.2)
	
	# Play hit animation
	
	animated_sprite_2d.play("hit")


func hide_item() -> void:
	animated_sprite_2d.visible = false
	point_light_2d.visible = false

func apply_bounce_to_player(player: CharacterBody2D) -> void:
	# Apply vertical bounce force without affecting horizontal velocity
	player.velocity.y = -jump_force
	
	player.handle_bounce()
	
	# Play jump animation on the player
	player.animated_sprite.play("jump")
	
	player.handle_bounce()
	
	# Play sound if player has an audio player
	if player.has_node("AudioStreamPlayer2D"):
		player.audio_stream_player_2d.play()



func _on_timer_timeout() -> void:
	# Re-enable collision
	collision_shape_2d.set_deferred("disabled", false)
	
	# Make sprite visible again
	animated_sprite_2d.visible = true
	
	point_light_2d.visible = true
	point_light_2d.energy = 0  # Start from zero
	
	var tween = get_tree().create_tween()
	tween.tween_property(point_light_2d, "energy", 1, 0.2)
	
	animated_sprite_2d.play("idle")
	
	can_bounce = true
