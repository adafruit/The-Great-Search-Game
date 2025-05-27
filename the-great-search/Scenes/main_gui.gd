extends CanvasLayer

@onready var requirements_label: Label = null

func _ready() -> void:
	Global.connect("update_score", update_score)
	$Label.text = str(Global.score)
	$SparkyScore.text = str(Global.sparkysVanquished)
	
	# Connect to requirements updates
	SceneRequirements.connect("requirements_updated", update_requirements_display)
	
	# Create requirements label if it doesn't exist
	if not has_node("RequirementsLabel"):
		requirements_label = Label.new()
		requirements_label.name = "RequirementsLabel"
		requirements_label.position = Vector2(20, 120)
		requirements_label.size = Vector2(400, 200)
		add_child(requirements_label)
	else:
		requirements_label = $RequirementsLabel
	
	# Initial update of requirements
	update_requirements_display()

func update_score() -> void:
	#label
	print("Update Score Called")
	$Label.text = str(Global.score)
	$SparkyScore.text = str(Global.sparkysVanquished)
	
	# Update requirements display when scores change
	update_requirements_display()

func update_requirements_display() -> void:
	if requirements_label:
		var current_scene = get_tree().current_scene.scene_file_path
		var req_text = SceneRequirements.get_requirements_text(current_scene)
		
		# Only show if there are requirements
		if req_text != "No requirements":
			requirements_label.text = req_text
			requirements_label.visible = true
		else:
			requirements_label.visible = false
