extends Camera2D

@export var room_size := Vector2(640, 360)
var current_room := Vector2.ZERO

func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
		
	var player = players[0]
	var target_room = (player.global_position / room_size).floor()
	
	if target_room != current_room:
		current_room = target_room
		var target_pos = current_room * room_size + (room_size / 2)
		global_position = target_pos
