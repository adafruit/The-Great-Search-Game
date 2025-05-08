extends Node2D

# Nodes
@onready var beam_holder = $Position2D
@onready var timer = $Timer
@onready var beam_collision = $Area2D/CollisionShape2D
@onready var beam_light = $Light2D
@onready var damage_timer = $damageTimer
@onready var cycle_timer = $CycleDelayTimer
@onready var respawn_manager = get_node_or_null("/root/RespawnGlobal")
@onready var area_2d = $Area2D

# Get all animated sprites
@onready var sprites = [
    $Position2D/AnimatedSprite2D,
    $Position2D/AnimatedSprite2D2,
    $Position2D/AnimatedSprite2D4,
    $Position2D/AnimatedSprite2D3,
    $Position2D/AnimatedSprite2D5,
    $Position2D/AnimatedSprite2D6,
    $Position2D/AnimatedSprite2D8,
    $Position2D/AnimatedSprite2D7
]

# Configuration
@export var cycle_time: float = 5.0  # Total time for one full cycle
@export var lightning_duration: float = 0.4  # How long each lightning animation displays
@export var lightning_delay: float = 0.1  # Delay between lightning animations
@export var beam_duration: float = 1.0  # How long the beam stays on

# State
var is_beam_active = false

func _ready():
    # Setup timers
    timer.wait_time = cycle_time
    damage_timer.wait_time = beam_duration
    
    # Connect signals
    timer.timeout.connect(_start_animation_sequence)
    damage_timer.timeout.connect(_end_beam)
    cycle_timer.timeout.connect(_restart_cycle)
    
    # Connect area signals
    area_2d.body_entered.connect(_on_area_2d_body_entered)
    
    # Hide all sprites initially
    for sprite in sprites:
        if sprite:
            sprite.visible = false
    
    # Start the cycle - first delay
    timer.start()
    print("Cannon initialized and cycle started")

# This function uses a simpler, more reliable approach without depending on animation signals
func _start_animation_sequence():
    print("Starting animation sequence")
    # Reset state
    is_beam_active = false
    beam_collision.set_deferred("disabled", true)
    
    # Use directly timed animations instead of signals
    _play_lightning_sequence_timed()

# Play lightning animations in sequence with timers instead of animation signals
func _play_lightning_sequence_timed():
    var total_lightning_time = (lightning_duration + lightning_delay) * sprites.size()
    
    # Schedule each lightning animation with explicit timing
    for i in range(sprites.size()):
        var delay = i * (lightning_duration + lightning_delay)
        get_tree().create_timer(delay).timeout.connect(func(): _show_lightning_at_index(i))
    
    # Schedule beam animation after all lightning is done
    get_tree().create_timer(total_lightning_time).timeout.connect(_play_beam_animations)

# Show lightning at specific index
func _show_lightning_at_index(index):
    print("Playing lightning on sprite " + str(index))
    # Hide all sprites first
    for sprite in sprites:
        if sprite:
            sprite.visible = false
    
    # Show and play this specific sprite
    if index < sprites.size() and sprites[index]:
        sprites[index].visible = true
        sprites[index].play("lightning")

# Play beam animation on all sprites simultaneously
func _play_beam_animations():
    print("Playing beam animation on all sprites simultaneously")
    
    # Show and play all sprites
    for sprite in sprites:
        if sprite:
            sprite.visible = true
            sprite.frame = 0  # Reset to first frame
            sprite.play("beam")
    
    # Enable collision
    is_beam_active = true
    beam_collision.set_deferred("disabled", false)
    
    # Light effect
    var tween = get_tree().create_tween()
    tween.tween_property(beam_light, "energy", 0, 0.2).from(2.5)
    
    # Start timer to end beam
    damage_timer.start()

func _end_beam():
    print("Ending beam")
    # Disable beam
    is_beam_active = false
    beam_collision.set_deferred("disabled", true)
    
    # Start delay before next cycle
    cycle_timer.start()

func _restart_cycle():
    print("Restarting cycle")
    # Hide all sprites
    for sprite in sprites:
        if sprite:
            sprite.visible = false
    
    # Start the next cycle
    timer.start()

func _on_area_2d_body_entered(body):
    print("Body entered beam: " + str(body.name))
    
    # Check if beam is active
    if not is_beam_active:
        return
        
    print("DEAD - Cannon hit player")
    # Try to respawn player
    if respawn_manager and respawn_manager.has_method("respawn_player"):
        respawn_manager.respawn_player(body)
    elif body.has_method("take_damage"):
        body.take_damage()