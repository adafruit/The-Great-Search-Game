extends Area2D

@export_file("*.tscn") var target_scene: String = ""
@export var neopixels_required: int = 0
@export var sparkys_required: int = 0
@export var key_collectibles_required: int = 0
@export var show_requirement_message: bool = true
@export var wait_time_after_entry: float = 0.5

@onready var dialogue_view = null
var player_in_area: bool = false

func _ready() -> void:
	# Register requirements
	if target_scene != "":
		SceneRequirements.set_scene_requirements(
			target_scene,
			neopixels_required,
			sparkys_required,
			key_collectibles_required
		)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func _process(_delta: float) -> void:
	# Check for interaction while player is in area
	#if player_in_area and Input.is_action_just_pressed("interaction"):
	#	attempt_transition()
	print("process")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		
		attempt_transition()
		
		# If requirements are not met, show dialogue
		if show_requirement_message and not SceneRequirements.are_requirements_met(target_scene):
			show_requirements_dialogue()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false

func attempt_transition() -> void:
	if target_scene.is_empty():
		return
	
	# Check requirements
	if SceneRequirements.are_requirements_met(target_scene):
		# All requirements met, do the transition
		SceneTransition.change_scene(target_scene)
	else:
		# Requirements not met, show dialogue
		show_requirements_dialogue()

func show_requirements_dialogue() -> void:
	if not dialogue_view:
		dialogue_view = get_tree().get_first_node_in_group("dialogue_view")
		
	if dialogue_view:
		var req_text = SceneRequirements.get_requirements_text(target_scene)
		dialogue_view.show_dialogue(
			"Path Blocked",
			req_text,
			"Complete requirements to proceed"
		)
		dialogue_view.is_welcome_message = true  # Allow dismissing with interaction key
