extends Area2D
@onready var interactable: InteractionArea = $Interactable
@onready var sprite_2d: Sprite2D = $Sprite2D

# Add export variables to make editable in the Inspector
@export var board_title: String = "Title"
@export_multiline var board_content: String = "Body"
@export var board_signature: String = "sig"

func _ready():
	# Set up the interaction area as a message board
	interactable.is_message = true
	
	# Use the exported variables
	interactable.message_title = board_title
	interactable.message_body = board_content
	interactable.message_secondary = board_signature
