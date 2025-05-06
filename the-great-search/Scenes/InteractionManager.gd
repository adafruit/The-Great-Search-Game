extends Node
#class_name InteractionManager

# UI references
var interact_label: Label
var base_text: String = "[S] to "


var dialogue_view = null

# State tracking
var active_areas = []
var can_interact = true

# References
var player: Node2D

func _ready():
	# Get player reference (delay until scene is ready)
	call_deferred("_setup")

func _setup():
	player = get_tree().get_first_node_in_group("player")
	
	dialogue_view = get_node("/root/InteractionManager/GUI/DialogueView")
	
	if dialogue_view == null:
		print("ERROR: Could not find DialogueView Control node")
	else:
		print("Found DialogueView at: ")
		
	if not interact_label:
		interact_label = Label.new()
		interact_label.add_theme_font_size_override("font_size", 12)
		interact_label.visible = false
		add_child(interact_label)

func register_area(area: InteractionArea):
	if not active_areas.has(area):
		active_areas.push_back(area)

func unregister_area(area: InteractionArea):
	var index = active_areas.find(area)
	if index != -1:
		active_areas.remove_at(index)

func _process(_delta):
	if active_areas.size() > 0 && can_interact:
		active_areas.sort_custom(sort_by_distance_to_player)
		var closest_area = active_areas[0]
		
		interact_label.text = base_text + closest_area.action_name
		interact_label.global_position = closest_area.global_position
		interact_label.global_position.y -= 36
		interact_label.global_position.x -= interact_label.size.x / 2
		interact_label.show()
	else:
		interact_label.hide()
		
		
func _input(event):
	if event.is_action_pressed("interaction") && can_interact && active_areas.size() > 0:
		can_interact = false
		interact_label.hide()
		
		var current_area = active_areas[0]
		
		print("Interaction detected with: ", current_area)
		print("Is message? ", current_area.is_message)
		print("Dialogue view found? ", dialogue_view != null)
		
		if current_area.is_message && dialogue_view != null:
			print("Showing dialogue for message: " + current_area.message_title)
			
			dialogue_view.title.text = current_area.message_title
			dialogue_view.body.text = current_area.message_body
			dialogue_view.secondary.text = current_area.message_secondary
			dialogue_view.visible = true
			
			await get_tree().create_timer(0.2).timeout
			
			var waiting_for_input = true
			while waiting_for_input:
				if Input.is_action_just_pressed("interaction"):
					dialogue_view.visible = false
					waiting_for_input = false
				await get_tree().process_frame
		else:
			await current_area.interact.call()
		await get_tree().create_timer(0.1).timeout
		can_interact = true

func sort_by_distance_to_player(area1, area2):
	var area1_distance = player.global_position.distance_to(area1.global_position)
	var area2_distance = player.global_position.distance_to(area2.global_position)
	return area1_distance < area2_distance
	
func find_dialogue_view() -> Control:
		
		var root = get_tree().root
		return find_node_by_group_recursive(root, "dialogue_view")
		
func find_node_by_group_recursive(node: Node, group_name: String) -> Control:
	if node.is_in_group(group_name) and node is Control:
		return node
		
	for child in node.get_children():
		var found = find_node_by_group_recursive(child, group_name)
		if found != null:
			return found
			
	return null
