extends Area2D
class_name JumpItem

@export var jump_force: float = 400.0
@export var reset_time: float = 1.0
@export var particle_effect: PackedScene
@onready var reset_timer: Timer = $"Reset Timer"
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var jump_item_animation: AnimatedSprite2D = $JumpItemAnimation
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


var can_bounce: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	reset_timer.wait_time = reset_time
	reset_timer.one_shot = true
	reset_timer.timeout.connect(_on_reset_timer_timeout)



func apply_bounce_to_player(player: CharacterBody2D) -> void:
	# Apply vertical bounce force without affecting horizontal velocity
	player.velocity.y = -jump_force
	
	# Play jump animation on the player
	player.animated_sprite.play("jump")
	
	# Play sound if player has an audio player
	if player.has_node("AudioStreamPlayer2D"):
		player.audio_stream_player_2d.play()

func _on_reset_timer_timeout() -> void:
	can_bounce = true
	if jump_item_animation:
		jump_item_animation.play("default")
	else:
		print("Else _on_reset_timer_timeout")


func _on_body_entered(body: Node2D) -> void:
	if not can_bounce:
		return
		
	if body.is_in_group("player"):
		# Apply bounce force without consuming player's jump
		apply_bounce_to_player(body)
		
		# Disable bouncing temporarily and play animation
		can_bounce = false
		if animated_sprite_2d:
			animated_sprite_2d.play("jump")
		else:
			# If no animation player, just modify the sprite
			print("Else _on_body_entered")
			
		# Spawn particle effect if provided
		if particle_effect:
			var particles = particle_effect.instantiate()
			particles.global_position = global_position
			get_tree().get_root().add_child(particles)
			
		reset_timer.start()
