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
	# Wait a frame to ensure all autoloads are initialized
	await get_tree().process_frame
	
	# Register requirements
	if target_scene != "" and has_node("/root/SceneRequirements"):
		# Print values for debugging
		print("Setting requirements for scene: ", target_scene)
		print("Neopixels required: ", neopixels_required)
		print("Sparkys required: ", sparkys_required)
		print("Key collectibles required: ", key_collectibles_required)
		
		# Set the requirements
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
	if player_in_area and Input.is_action_just_pressed("interaction"):
		print("attempt_transition()")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		
		# Check requirements on entry
		var requirements_met = false
		
		# Check if SceneRequirements singleton is available
		if has_node("/root/SceneRequirements"):
			requirements_met = SceneRequirements.are_requirements_met(target_scene)
		else:
			# Fallback to manual requirements check
			requirements_met = (
				Global.score >= neopixels_required &&
				Global.sparkysVanquished >= sparkys_required &&
				Global.keyCollectibles >= key_collectibles_required
			)
		
		# If requirements are not met, show dialogue
		if show_requirement_message and not requirements_met:
			show_requirements_dialogue()
		else: 
			attempt_transition()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false

func attempt_transition() -> void:
	if target_scene.is_empty():
		return
	
	var requirements_met = false
	
	# Check if SceneRequirements singleton is available
	if has_node("/root/SceneRequirements"):
		requirements_met = SceneRequirements.are_requirements_met(target_scene)
	else:
		# Fallback to manual requirements check
		requirements_met = (
			Global.score >= neopixels_required &&
			Global.sparkysVanquished >= sparkys_required &&
			Global.keyCollectibles >= key_collectibles_required
		)
	
	# Check requirements
	if requirements_met:
		print("Requirements met! Transitioning to: ", target_scene)
		# All requirements met, do the transition
		if has_node("/root/SceneTransition"):
			SceneTransition.change_scene(target_scene)
		else:
			# Fallback if SceneTransition is not available
			get_tree().change_scene_to_file(target_scene)
	else:
		print("Requirements NOT met for: ", target_scene)
		print("Current values - Neopixels: ", Global.score, ", Sparkys: ", Global.sparkysVanquished, ", Keys: ", Global.keyCollectibles)
		# Requirements not met, show dialogue
		show_requirements_dialogue()

func show_requirements_dialogue() -> void:
	if not dialogue_view:
		dialogue_view = get_tree().get_first_node_in_group("dialogue_view")
		
	if dialogue_view:
		# Generate custom requirements text if SceneRequirements is not available
		var req_text = ""
		
		if has_node("/root/SceneRequirements"):
			req_text = SceneRequirements.get_requirements_text(target_scene)
		else:
			# Fallback manual requirements text
			req_text = "Requirements to proceed:\n"
			
			if neopixels_required > 0:
				req_text += "- Collect %d/%d Neopixels\n" % [min(Global.score, neopixels_required), neopixels_required]
			
			if sparkys_required > 0:
				req_text += "- Defeat %d/%d Sparkys\n" % [min(Global.sparkysVanquished, sparkys_required), sparkys_required]
				
			if key_collectibles_required > 0:
				req_text += "- Find %d/%d Key Items\n" % [min(Global.keyCollectibles, key_collectibles_required), key_collectibles_required]
		
		dialogue_view.show_dialogue(
			"Path Blocked",
			req_text,
			"Complete requirements to proceed"
		)
		dialogue_view.is_welcome_message = true  # Allow dismissing with interaction key
