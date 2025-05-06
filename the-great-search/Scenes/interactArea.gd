extends Area2D
class_name InteractionArea

@export var action_name: String = "interact"
@export var is_message: bool = false  # New property to identify message objects
@export var message_title: String = "Message"  # Title for the message
@export var message_body: String = "Text content goes here"  # Main message content
@export var message_secondary: String = ""  # Optional secondary text

var interact: Callable = func(): pass

func _ready():
	# Change action name automatically if this is a message
	if is_message:
		action_name = "read"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.register_area(self)
		
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister_area(self)
