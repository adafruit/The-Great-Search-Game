extends Control
@onready var title: Label = $ColorRect/VBoxContainer/Title
@onready var body: Label = $ColorRect/VBoxContainer/Body
@onready var secondary: Label = $ColorRect/VBoxContainer/Secondary
@onready var color_rect: ColorRect = $ColorRect

func _ready():
	print("DialogueView initialized")
	add_to_group("dialogue_view")
	visible = false  # Start hidden
	
	# Store the original color to ensure it's preserved
	original_color = color_rect.color
	print("Original ColorRect color: ", original_color)

# Add a variable to store the original color
var original_color: Color

# Add this function to be called when dialogue is shown
func show_dialogue(title_text: String, body_text: String, secondary_text: String = ""):
	print("Dialogue triggered: " + title_text)
	
	# Set the content
	title.text = title_text
	body.text = body_text
	secondary.text = secondary_text
	
	# Ensure the ColorRect has the right color
	color_rect.color = original_color
	print("Setting ColorRect color to: ", color_rect.color)
	
	# Make everything visible
	self.modulate = Color(1, 1, 1, 0)  # Start transparent
	visible = true
	
	# Create a simple fade-in effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
