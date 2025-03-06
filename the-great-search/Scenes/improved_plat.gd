extends Node2D
@onready var platform: Node2D = $"."
@onready var static_body_2d: StaticBody2D = $StaticBody2D
@onready var collision_shape_2d: CollisionShape2D = $StaticBody2D/Area2D/CollisionShape2D

@onready var sprite_2d: Sprite2D = $StaticBody2D/Sprite2D
@onready var timer: Timer = $Timer
@onready var reset_timer: Timer = $ResetTimer
var is_active = true
var flash_count = 0
const MAX_FLASHES = 3
const FLASH_DURATION = 0.3
const RESET_TIME = 2.0

func _ready() -> void:
	print("Ready")
	print("collision_shape_2d: ", collision_shape_2d)
	
	if !has_node("Timer"):
		var new_timer = Timer.new()
		new_timer.name = "Timer"
		new_timer.one_shot = true
		add_child(new_timer)
		timer = new_timer
		
	if !has_node("ResetTimer"):
		var new_timer = Timer.new()
		new_timer.name = "ResetTimer"
		new_timer.one_shot = true
		add_child(new_timer)
		reset_timer = new_timer
	
	# Create Area2D for player detection
	var area_2d = Area2D.new()
	area_2d.name = "DetectionArea"
	add_child(area_2d)
	
	var area_shape = CollisionShape2D.new()
	area_shape.shape = collision_shape_2d.shape.duplicate()
	area_shape.position = collision_shape_2d.position
	area_shape.position.y -= 5  # Slightly above the platform
	area_2d.add_child(area_shape)
		
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	timer.timeout.connect(_on_timer_timeout)
	reset_timer.timeout.connect(_on_reset_timer_timeout)
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	print("_on_area_2d_body_entered")
	if body.is_in_group("player") and is_active:
		start_vanishing_sequence()
		print("Started Sequence _on_area_2d_body_entered")
		
func start_vanishing_sequence() -> void:
	is_active = false
	flash_count = 0
	flash_platform()
	
func flash_platform() -> void:
	flash_count += 1
	
	var tween = create_tween()
	tween.tween_property(sprite_2d, "modulate:a", 0.3, FLASH_DURATION/2)
	tween.tween_property(sprite_2d, "modulate:a", 1.0, FLASH_DURATION/2)
	
	if flash_count < MAX_FLASHES:
		timer.wait_time = FLASH_DURATION
		timer.start()
	else:
		timer.wait_time = FLASH_DURATION
		timer.start()
		
func _on_timer_timeout() -> void:
	if flash_count < MAX_FLASHES:
		flash_platform()
	else:
		var tween = create_tween()
		tween.tween_property(sprite_2d, "modulate:a", 0.0, FLASH_DURATION/2)
		tween.tween_callback(disable_platform)
		
func disable_platform() -> void:
	collision_shape_2d.set_deferred("disabled", true)
	reset_timer.wait_time = RESET_TIME
	reset_timer.start()
	
func _on_reset_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(sprite_2d, "modulate:a", 1.0, 0.5)
	collision_shape_2d.set_deferred("disabled", false)
	is_active = true
