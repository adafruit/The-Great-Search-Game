# MenuManager.gd
extends Node

# References to menu scenes
#@onready var main_menu = preload("res://scenes/ui/MainMenu.tscn")
#@onready var options_menu = preload("res://scenes/ui/OptionsMenu.tscn")
#@onready var pause_menu = preload("res://scenes/ui/PauseMenu.tscn")

# Menu state
var current_menu = null
var is_game_paused = false

# Game state reference
var game_state

func _ready():
	# Connect signals from game state if needed
	pass

func _input(event):
	# Check for pause input (e.g., ESC key)
	if event.is_action_pressed("ui_cancel") and game_state.is_gameplay_active:
		toggle_pause_menu()

func toggle_pause_menu():
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	
	if is_game_paused:
		show_menu("pause")
	else:
		hide_all_menus()

func show_menu(menu_type):
	# Hide any current menu first
	hide_all_menus()
	
	# Instantiate and show the requested menu
	#match menu_type:
	#	"main":
	#		current_menu = main_menu.instantiate()
	#	"options":
	#		current_menu = options_menu.instantiate()
	#	"pause":
	#		current_menu = pause_menu.instantiate()
	
	if current_menu:
		add_child(current_menu)
		# Connect menu button signals
		_connect_menu_signals()

func hide_all_menus():
	if current_menu:
		current_menu.queue_free()
		current_menu = null

func _connect_menu_signals():
	# Connect signals from buttons to their respective functions
	if current_menu.has_node("StartButton"):
		current_menu.get_node("StartButton").pressed.connect(self._on_start_pressed)
	if current_menu.has_node("OptionsButton"):
		current_menu.get_node("OptionsButton").pressed.connect(self._on_options_pressed)
	if current_menu.has_node("QuitButton"):
		current_menu.get_node("QuitButton").pressed.connect(self._on_quit_pressed)
	if current_menu.has_node("ResumeButton"):
		current_menu.get_node("ResumeButton").pressed.connect(self._on_resume_pressed)
	# Add more connections as needed

func _on_start_pressed():
	hide_all_menus()
	is_game_paused = false
	get_tree().paused = false
	game_state.start_game()

func _on_options_pressed():
	show_menu("options")

func _on_resume_pressed():
	toggle_pause_menu()

func _on_quit_pressed():
	get_tree().quit()
