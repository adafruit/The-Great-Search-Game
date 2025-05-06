extends Area2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


@onready var interaction_area = $InteractionArea

func _ready():
	# Set up the interaction
	interaction_area.action_name = "Proceed?"
	interaction_area.interact = func():
		print("Go To Adafruit 1?")
		
		# Add your chest opening logic here
		await get_tree().create_timer(1.0).timeout  # Optional delay
		return


func _on_body_entered(body: Node2D) -> void:
	print("With mask on entered")
	animated_sprite_2d.play("open")


func _on_body_exited(body: Node2D) -> void:
	print("With mask on exited")
	animated_sprite_2d.play("close")
