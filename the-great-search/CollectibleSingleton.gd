extends Node
class_name CollectibleManager

# Signals
signal score_updated(new_score)
signal health_updated(new_health)
signal gem_collected(gem_count)
signal key_collected(key_id)
signal power_up_collected(power_up_type)

# Player stats
var score: int = 0
var health: int = 3
var max_health: int = 5
var gems_collected: int = 0
var keys: Dictionary = {}
var active_power_ups: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func register_collectible(collectible: Collectible) -> void:
	collectible.collected.connect(_on_collectible_collected)
	
func _on_collectible_collected(type: Collectible.CollectibleType, value: int) -> void:
	match type:
		Collectible.CollectibleType.COIN:
			score += value
			score_updated.emit(score)
			
		Collectible.CollectibleType.GEM:
			gems_collected += value
			gem_collected.emit(gems_collected)
			
		Collectible.CollectibleType.HEALTH:
			health = min(health + value, max_health)
			health_updated.emit(health)
			
		Collectible.CollectibleType.KEY:
			keys[value] = true
			key_collected.emit(value)
			
		Collectible.CollectibleType.POWER_UP:
			apply_power_up(value)
			power_up_collected.emit(value)

func apply_power_up(power_up_id: int) -> void:
	# Implement different power-up effects
	match power_up_id:
		1: # Double jump
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.has_double_jump = true
				# Set expiration if needed
				
		2: # Speed boost
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.SPEED *= 1.5
				
				# Create a timer to reset the speed
				var timer = get_tree().create_timer(10.0)
				timer.timeout.connect(func(): player.SPEED /= 1.5)
				
		# Add more power-ups as needed
			
func reset() -> void:
	score = 0
	health = 3
	gems_collected = 0
	keys.clear()
	active_power_ups.clear()
