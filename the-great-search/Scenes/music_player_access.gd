extends Area2D

@export var interaction_distance: float = 100.0
@export var player_prompt_text: String = "Music Player"

@onready var interaction_label: Label = $InteractionLabel
@onready var interactable: Node = $Interactable

var player_in_range: bool = false
var music_player_scene = preload("res://Scenes/UI/music_player.tscn")

func _ready() -> void:
	# Set up the interaction label
	interaction_label.visible = false
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up interactable if available
	if interactable and interactable is InteractionArea:
		interactable.is_message = false
		interactable.action_name = "access music player"

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interaction"):
		open_music_player()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		interaction_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		interaction_label.visible = false

func open_music_player() -> void:
	# Instantiate the music player scene
	var music_player_instance = music_player_scene.instantiate()
	
	# Find the UI Canvas layer to add it to
	var ui_layer = get_node_or_null("/root/InteractionManager/GUI")
	if not ui_layer:
		ui_layer = get_tree().root
	
	# Add the music player to the UI
	ui_layer.add_child(music_player_instance)