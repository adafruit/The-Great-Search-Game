extends Area2D


	
func _process(delta): 
		pass

func _on_body_entered(body: Node2D) -> void:
	print("I'm mho!")
	queue_free()
