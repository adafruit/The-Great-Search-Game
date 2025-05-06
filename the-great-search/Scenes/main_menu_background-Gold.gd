extends Node2D

@export var animation_delay: float = 3.0
@export var camera_move_speed: float = 300.0
@export var animation_duration: float = 2.0
@export var debug_mode: bool = true

var camera: Camera2D
var animation_timer: Timer

func _ready() -> void:
	# Find the Camera2D in the scene
	camera = find_camera()
	
	if camera:
		if debug_mode:
			print("Camera2D found: " + camera.name)
		
		# Create and start the animation timer
		animation_timer = Timer.new()
		animation_timer.wait_time = animation_delay
		animation_timer.one_shot = true
		add_child(animation_timer)
		animation_timer.timeout.connect(animate_camera)
		animation_timer.start()
		
		if debug_mode:
			print("Animation will start in " + str(animation_delay) + " seconds")
	else:
		print("ERROR: No Camera2D found in the scene!")

# Function to find the Camera2D in the scene
func find_camera() -> Camera2D:
	# First check if it's a direct child of this node
	for child in get_children():
		if child is Camera2D:
			return child
	
	# If not found as direct child, search the entire scene tree
	return find_camera_in_children(self)

# Recursive function to find Camera2D in children
func find_camera_in_children(node: Node) -> Camera2D:
	for child in node.get_children():
		if child is Camera2D:
			return child
		
		var result = find_camera_in_children(child)
		if result:
			return result
	
	return null

# Animate the camera to move upwards
func animate_camera() -> void:
	if debug_mode:
		print("Starting camera animation")
	
	# Get current camera position
	var start_position = camera.position
	var end_position = start_position + Vector2(0, -camera_move_speed)
	
	# Create tween for camera movement
	var tween = create_tween()
	tween.tween_property(camera, "position", end_position, animation_duration)
	
	if debug_mode:
		print("Camera moving from " + str(start_position) + " to " + str(end_position))
		
		# Connect to tween finished signal
		tween.finished.connect(func(): print("Camera animation complete"))
