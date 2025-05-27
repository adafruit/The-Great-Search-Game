extends Node

signal requirements_updated
signal requirement_completed(requirement_id: String)

# Map of scene paths to requirements
var scene_requirements = {
	# Example: "res://Scenes/Level2.tscn": {
	#   "neopixels": 5,
	#   "sparkys": 3,
	#   "key_collectibles": 1
	# }
}

# Initialize requirements for a scene
func set_scene_requirements(scene_path: String, neopixels: int = 0, sparkys: int = 0, key_collectibles: int = 0) -> void:
	scene_requirements[scene_path] = {
		"neopixels": neopixels,
		"sparkys": sparkys,
		"key_collectibles": key_collectibles
	}
	requirements_updated.emit()

# Check if requirements are met for a scene
func are_requirements_met(scene_path: String) -> bool:
	if not scene_requirements.has(scene_path):
		return true  # No requirements for this scene
	
	var reqs = scene_requirements[scene_path]
	
	# Check if all requirements are met
	if Global.score < reqs.get("neopixels", 0):
		return false
	
	if Global.sparkysVanquished < reqs.get("sparkys", 0):
		return false
		
	if Global.keyCollectibles < reqs.get("key_collectibles", 0):
		return false
	
	return true

# Get formatted requirements text for a scene
func get_requirements_text(scene_path: String) -> String:
	if not scene_requirements.has(scene_path):
		return "No requirements"
	
	var reqs = scene_requirements[scene_path]
	var text = "Requirements to proceed:\n"
	
	if reqs.get("neopixels", 0) > 0:
		text += "- Collect %d/%d Neopixels\n" % [min(Global.score, reqs.neopixels), reqs.neopixels]
	
	if reqs.get("sparkys", 0) > 0:
		text += "- Defeat %d/%d Sparkys\n" % [min(Global.sparkysVanquished, reqs.sparkys), reqs.sparkys]
		
	if reqs.get("key_collectibles", 0) > 0:
		text += "- Find %d/%d Key Items\n" % [min(Global.keyCollectibles, reqs.key_collectibles), reqs.key_collectibles]
	
	return text

# Check if a specific requirement type is met
func is_requirement_met(scene_path: String, req_type: String) -> bool:
	if not scene_requirements.has(scene_path):
		return true
		
	var reqs = scene_requirements[scene_path]
	
	match req_type:
		"neopixels":
			return Global.score >= reqs.get("neopixels", 0)
		"sparkys":
			return Global.sparkysVanquished >= reqs.get("sparkys", 0)
		"key_collectibles":
			return Global.keyCollectibles >= reqs.get("key_collectibles", 0)
		_:
			return true