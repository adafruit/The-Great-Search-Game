extends Area2D
class_name Collectible

@export var value: int = 1
@export var shake_amount: float = 1.0
@export var shake_duration: float = 0.15
@export var sprite_texture: Texture2D
@onready var kill_timer: Timer = $Timer

@onready var audio_stream_player_2d: AudioStreamPlayer2D

@onready var sprite: Sprite2D
@onready var collision_shape: CollisionShape2D

# Collectible type for tracking different kinds
enum CollectibleType {COIN, GEM, HEALTH, POWER_UP, KEY}
@export var type: CollectibleType = CollectibleType.COIN

signal collected(type, value)

func _ready() -> void:
	# Setup children nodes
	audio_stream_player_2d = $AudioStreamPlayer2D
	sprite = $Sprite2D
	collision_shape = $CollisionShape2D
	
	# Set sprite texture if provided
	if sprite_texture:
		sprite.texture = sprite_texture
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	kill_timer.timeout.connect(_on_kill_timer_timeout)
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect(body)
		
func collect(collector: Node2D) -> void:
	# Base collection behavior
	audio_stream_player_2d.play()
	collision_shape.set_deferred("disabled", true)
	
	# Simple collect animation (scale down and fade out)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.3)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 0.3)
	
	# Signal the collection
	collected.emit(type, value)
	Global.keyCollectibles += value
	print(Global.keyCollectibles)
	Global.update_score.emit()
	# Visual feedback
	var camera = get_viewport().get_camera_2d()
	if camera:
		shake_camera(camera)
	
	# Start timer to remove from scene
	kill_timer.start()
	
func _on_kill_timer_timeout() -> void:
	queue_free()
	
func shake_camera(camera: Camera2D) -> void:
	var shake_tween = get_tree().create_tween()
	var original_offset = camera.offset
	
	for i in range(10):
		var rand_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_tween.tween_property(camera, "offset", original_offset + rand_offset, shake_duration / 10.0)
	
	shake_tween.tween_property(camera, "offset", original_offset, shake_duration / 10.0)
