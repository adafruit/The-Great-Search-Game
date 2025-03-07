extends Area2D

@onready var interactable: InteractionArea = $Interactable
@onready var sprite_2d: Sprite2D = $Sprite2D

func _ready():
	interactable.interact = Callable(self, "_toggle_board")
	
func _toggle_board():
	print("Toggled Board")
