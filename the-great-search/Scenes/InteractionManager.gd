extends Node2D
#class_name InteractionManager 

@onready var player = get_tree().get_first_node_in_group("player")

@onready var interact_label: Label = $InteractLabel

@export var action_name: String = "interaction"

@export var interact_name: String = ""
@export var is_interactable: bool = true

const base_text = "[S] to "

var active_areas = []
var can_interact = true


func register_area(area: InteractionArea):
	active_areas.push_back(area)

func unregister_area(area: InteractionArea):
	var index = active_areas.find(area)
	if index != -1:
		active_areas.remove_at(index)

func _process(delta):
	if active_areas.size() > 0 && can_interact:
		active_areas.sort_custom(sort_by_distance_to_player)
		interact_label.text = base_text + active_areas[0].action_name
		interact_label.global_position = active_areas[0].global_position
		interact_label.global_position.y -= 36
		interact_label.global_position.x -= interact_label.size.x / 2
		interact_label.show()
	else:
		interact_label.hide()
	
func _input(event):
	if event.is_action_pressed("interaction") && can_interact:
		if active_areas.size() > 0:
			can_interact = false 
			interact_label.hide()
			
			await active_areas[0].interact.call()
			can_interact = true
			


func sort_by_distance_to_player(area1, area2):
	var area1_distance = player.global_position.distance_to(area1.global_position)
	var area2_distance = player.global_position.distance_to(area2.global_position)
	return area1_distance < area2_distance

var interact: Callable = func():
	pass


func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
