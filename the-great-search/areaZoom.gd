extends Area2D

@export var zoom_level = Vector2(6, 6)  # Zoom in (values less than 1 zoom in)
@export var zoom_speed = 0.5  # Speed of zoom transition
@export var position_offset = Vector2(0, 100)  # Y positive means lower on screen

@onready var camera_2d: Camera2D = $"../Camera2D"
var original_zoom = Vector2(1, 1)
var original_position_offset = Vector2.ZERO
var player_inside = false

func _ready():
	print("Area2D zoom script initialized")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Store the original values once the camera is available
	if camera_2d:
		print("Camera found: ", camera_2d.name)
		original_zoom = camera_2d.zoom
		original_position_offset = camera_2d.offset
		print("Original zoom set to: ", original_zoom)
		print("Original offset set to: ", original_position_offset)
	else:
		print("ERROR: Camera not found at path ../Camera2D")

func _process(delta):
	if camera_2d == null:
		print("Camera is null, trying to find again")
		camera_2d = get_node_or_null("../Camera2D")
		if camera_2d:
			original_zoom = camera_2d.zoom
			original_position_offset = camera_2d.offset
		return
		
	if player_inside:
		# Gradually zoom in and move down
		camera_2d.zoom = camera_2d.zoom.lerp(zoom_level, zoom_speed * delta)
		camera_2d.offset = camera_2d.offset.lerp(position_offset, zoom_speed * delta)
	else:
		# Gradually zoom back out and restore position
		camera_2d.zoom = camera_2d.zoom.lerp(original_zoom, zoom_speed * delta)
		camera_2d.offset = camera_2d.offset.lerp(original_position_offset, zoom_speed * delta)

func _on_body_entered(body):
	print("Body entered: ", body.name)
	# Check if the entering body is the player
	if body.is_in_group("player"):
		print("Player entered zoom area")
		player_inside = true

func _on_body_exited(body):
	print("Body exited: ", body.name)
	# Check if the exiting body is the player
	if body.is_in_group("player"):
		print("Player exited zoom area")
		player_inside = false
