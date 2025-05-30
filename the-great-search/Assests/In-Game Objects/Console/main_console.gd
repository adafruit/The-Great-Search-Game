extends Area2D

@export_category("Console Settings")
@export var check_neopixels: bool = true
@export var check_sparkys: bool = false
@export var check_key_collectibles: bool = false

@export_category("Animation Thresholds")
@export var neopixels_error_threshold: int = 0  # Below this shows error
@export var neopixels_searching_threshold: int = 5  # Below this shows searching
@export var neopixels_loading_threshold: int = 15  # Below this shows loading
@export var neopixels_found_threshold: int = 25  # Above this shows found

@export var sparkys_error_threshold: int = 0
@export var sparkys_searching_threshold: int = 3
@export var sparkys_loading_threshold: int = 6
@export var sparkys_found_threshold: int = 10

@export var key_collectibles_error_threshold: int = 0
@export var key_collectibles_searching_threshold: int = 1
@export var key_collectibles_loading_threshold: int = 2
@export var key_collectibles_found_threshold: int = 3

@export_category("Interaction")
@export var interactive: bool = true
@export var show_message_on_interact: bool = true
@export var console_message_title: String = "Console Status"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable: Node = $Interactable

# Current state of the console
var current_state: String = "error"

func _ready() -> void:
	# Connect to the global update_score signal to update animation
	Global.connect("update_score", update_console_state)
	
	# Set up interactable area if available
	if interactive and interactable and interactable is InteractionArea:
		interactable.is_message = true
	
	# Set initial state
	update_console_state()
	
	# Play the animation for the current state
	play_animation_for_state()

# Called when global score is updated
func update_console_state() -> void:
	var new_state = determine_console_state()
	
	# Only update if the state has changed
	if new_state != current_state:
		current_state = new_state
		play_animation_for_state()
		update_interaction_message()

# Determine console state based on collected items
func determine_console_state() -> String:
	var neopixels = Global.score
	var sparkys = Global.sparkysVanquished
	var key_items = Global.keyCollectibles
	
	# Calculate state for each type of collectible
	var neopixel_state = "found"
	var sparky_state = "found"
	var key_state = "found"
	
	# Neopixels state
	if check_neopixels:
		if neopixels < neopixels_error_threshold:
			neopixel_state = "error"
		elif neopixels < neopixels_searching_threshold:
			neopixel_state = "searching"
		elif neopixels < neopixels_loading_threshold:
			neopixel_state = "loading"
		elif neopixels < neopixels_found_threshold:
			neopixel_state = "loading"
		else:
			neopixel_state = "found"
	
	# Sparkys state
	if check_sparkys:
		if sparkys < sparkys_error_threshold:
			sparky_state = "error"
		elif sparkys < sparkys_searching_threshold:
			sparky_state = "searching"
		elif sparkys < sparkys_loading_threshold:
			sparky_state = "loading"
		elif sparkys < sparkys_found_threshold:
			sparky_state = "loading"
		else:
			sparky_state = "found"
	
	# Key collectibles state
	if check_key_collectibles:
		if key_items < key_collectibles_error_threshold:
			key_state = "error"
		elif key_items < key_collectibles_searching_threshold:
			key_state = "searching"
		elif key_items < key_collectibles_loading_threshold:
			key_state = "loading"
		elif key_items < key_collectibles_found_threshold:
			key_state = "loading"
		else:
			key_state = "found"
	
	# Determine overall state (worst state takes precedence)
	var states = []
	if check_neopixels:
		states.append(neopixel_state)
	if check_sparkys:
		states.append(sparky_state)
	if check_key_collectibles:
		states.append(key_state)
	
	# If no collectible type is checked, default to "error"
	if states.size() == 0:
		return "error"
	
	# Error takes highest precedence, then searching, loading, found
	if states.has("error"):
		return "error"
	elif states.has("searching"):
		return "searching"
	elif states.has("loading"):
		return "loading"
	else:
		return "found"

# Play the appropriate animation for the current state
func play_animation_for_state() -> void:
	if animated_sprite and animated_sprite.sprite_frames.has_animation(current_state):
		animated_sprite.play(current_state)
	else:
		print("Warning: Animation '", current_state, "' not found for console")

# Update the interaction message based on current state
func update_interaction_message() -> void:
	if interactive and interactable and interactable is InteractionArea:
		var message_body = ""
		
		match current_state:
			"error":
				message_body = "ERROR: Insufficient data collected."
			"searching":
				message_body = "SEARCHING: More data required."
			"loading":
				message_body = "LOADING: Almost there..."
			"found":
				message_body = "SUCCESS: All required data collected!"
		
		# Add specific requirements
		message_body += "\n\nCurrent status:"
		
		if check_neopixels:
			message_body += "\nNeopixels: " + str(Global.score) + "/" + str(neopixels_found_threshold)
		
		if check_sparkys:
			message_body += "\nSparkys defeated: " + str(Global.sparkysVanquished) + "/" + str(sparkys_found_threshold)
			
		if check_key_collectibles:
			message_body += "\nKey items: " + str(Global.keyCollectibles) + "/" + str(key_collectibles_found_threshold)
		
		# Set the message on the interactable
		interactable.message_title = console_message_title
		interactable.message_body = message_body
		interactable.message_secondary = "Press [S] to close"
