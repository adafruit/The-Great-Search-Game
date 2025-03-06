extends AnimatableBody2D

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var is_active = true
var flash_count = 0
const MAX_FLASHES = 3
const FLASH_DURATION = 0.3
const RESET_TIME = 2.0
@onready var timer: Timer = $Timer
@onready var reset_timer: Timer = $ResetTimer

@onready var area_2d: Area2D = $Area2D


func _ready() -> void:
	# Create timers
	timer = Timer.new()
	timer.name = "Timer"
	timer.one_shot = true
	add_child(timer)
	
	reset_timer = Timer.new()
	reset_timer.name = "ResetTimer"
	reset_timer.one_shot = true
	add_child(reset_timer)
	
	# Create detection area
	area_2d = Area2D.new()
	area_2d.name = "DetectionArea"
	add_child(area_2d)
	
	var area_shape = CollisionShape2D.new()
	area_shape.shape = collision_shape_2d.shape.duplicate()
	area_shape.position = Vector2.ZERO
	area_shape.position.y -= 5  # Slightly above the platform
	area_2d.add_child(area_shape)
	
	# Connect signals
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	timer.timeout.connect(_on_timer_timeout)
	reset_timer.timeout.connect(_on_reset_timer_timeout)

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Touched")
	if body.is_in_group("player") and is_active:
		start_vanishing_sequence()
		
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
