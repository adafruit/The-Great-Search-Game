extends CanvasLayer
@onready var label: Label = $Label


func _ready() -> void:
	Global_Score.connect("update_score", update_score)
	label.text = "0"

func update_score() -> void:
	label.text = str(Global_Score.score)
