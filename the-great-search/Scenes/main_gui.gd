extends CanvasLayer

func _ready() -> void:
	Global.connect("update_score", update_score)
	$Label.text = str(Global.score)
	$SparkyScore.text = str(Global.sparkysVanquished)

func update_score() -> void:
	#label
	print("Update Score Called")
	$Label.text = str(Global.score)
	$SparkyScore.text = str(Global.sparkysVanquished)
