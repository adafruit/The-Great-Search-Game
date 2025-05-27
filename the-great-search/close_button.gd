extends Node2D
@onready var button: Button = $Button

func _ready():
	# Connect the button's pressed signal to our close function
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed():
	# Find the DialogueView parent
	var dialogue_view = find_dialogue_view_parent()
	if dialogue_view:
		# Call hide_dialogue if it exists
		if dialogue_view.has_method("hide_dialogue"):
			dialogue_view.hide_dialogue()
		# Fallback to just hiding the dialogue if hide_dialogue doesn't exist
		else:
			dialogue_view.visible = false

# Find the DialogueView parent recursively
func find_dialogue_view_parent() -> Node:
	var current = get_parent()
	while current:
		if current.is_in_group("dialogue_view"):
			return current
		current = current.get_parent()
	return null
