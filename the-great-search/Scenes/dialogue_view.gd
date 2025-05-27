extends Control
@onready var title: Label = $ColorRect/VBoxContainer/Title
@onready var body: Label = $ColorRect/VBoxContainer/Body
@onready var secondary: Label = $ColorRect/VBoxContainer/Secondary
@onready var color_rect: ColorRect = $ColorRect

# Track if dialogue is currently being shown
var is_showing_dialogue := false

func _ready():
	print("DialogueView initialized")
	add_to_group("dialogue_view")
	visible = false  # Start hidden
	
	# Store the original color to ensure it's preserved
	original_color = color_rect.color
	print("Original ColorRect color: ", original_color)

# Add a variable to store the original color
var original_color: Color

# Process input to handle dialogue dismissal only for the welcome message
# We use a dedicated variable to track if this is the welcome message
var is_welcome_message := false

func _input(event):
	# Only handle input for welcome message, not for message boards
	if is_showing_dialogue and is_welcome_message and event.is_action_pressed("interaction"):
		hide_dialogue()
		is_welcome_message = false

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
	is_showing_dialogue = true
	
	# Create a simple fade-in effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)

# Function to hide the dialogue with a fade-out effect
func hide_dialogue():
	if not is_showing_dialogue:
		return
		
	# Create a fade-out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	tween.tween_callback(func(): 
		visible = false
		is_showing_dialogue = false
		
		# Notify the InteractionManager that the dialogue was closed if this is not a welcome message
		if not is_welcome_message:
			var interaction_manager = get_node_or_null("/root/InteractionManager")
			if interaction_manager and interaction_manager.has_method("dialogue_closed_by_button"):
				interaction_manager.dialogue_closed_by_button()
	)
