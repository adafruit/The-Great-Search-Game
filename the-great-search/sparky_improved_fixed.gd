extends CharacterBody2D

class_name ImprovedFlyingEnemy

# Enemy properties
@export var float_speed: float = 40.0
@export var chase_speed: float = 150.0
@export var detection_radius: float = 200.0
@export var float_radius: float = 50.0
@export var float_frequency: float = 1.5
@export var respawn_time: float = 3.0  # Time it takes to respawn
@export var shake_intensity: float = 5.0  # How much the enemy shakes when self-destructing
@export var shake_duration: float = 0.5  # How long the enemy shakes before exploding

# State machine
enum State {
    PATROL,
    CHASE,
    ATTACK,
    DEATH,
    RESPAWN
}

# Internal variables
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var collision_shape: CollisionShape2D = $CollisionShape
@onready var detection_area: Area2D = $DetectionArea
@onready var hit_box: Area2D = $Hitbox

var value: int = 1
var current_state: State = State.PATROL
var player_ref: CharacterBody2D = null
var float_timer: float = 0.0
var home_position: Vector2
var original_position: Vector2
var respawn_timer: float = 0.0
var is_shaking: bool = false
var shake_timer: float = 0.0
var original_sprite_position: Vector2

func _ready() -> void:
    add_to_group("enemy")
    
    # Store original position for respawning
    original_position = global_position
    home_position = global_position
    
    # Store original sprite position for shake effect
    if animated_sprite:
        original_sprite_position = animated_sprite.position
    else:
        push_error("AnimatedSprite not found! Make sure it's named 'AnimatedSprite'")
    
    # Connect signals for detection area - ONLY for detecting player presence
    if detection_area:
        # Clear any existing connections to avoid duplicate signals
        if detection_area.body_entered.is_connected(_on_detection_area_body_entered):
            detection_area.body_entered.disconnect(_on_detection_area_body_entered)
        
        if detection_area.body_exited.is_connected(_on_detection_area_body_exited):
            detection_area.body_exited.disconnect(_on_detection_area_body_exited)
            
        # Connect detection area signals
        detection_area.body_entered.connect(_on_detection_area_body_entered)
        detection_area.body_exited.connect(_on_detection_area_body_exited)
        
        # Make sure detection area is set up correctly
        detection_area.collision_layer = 0  # No collision, just detection
        detection_area.collision_mask = 2   # Detect player layer
    else:
        push_error("DetectionArea not found! Make sure it's named 'DetectionArea'")
    
    # Connect signals for hitbox - Used for damage and player collision
    if hit_box:
        # Clear any existing connections
        if hit_box.body_entered.is_connected(_on_hit_box_body_entered):
            hit_box.body_entered.disconnect(_on_hit_box_body_entered)
            
        # Connect hitbox signal
        hit_box.body_entered.connect(_on_hit_box_body_entered)
        
        # Set up hitbox collision properly
        hit_box.collision_layer = 4  # Enemy hitbox layer
        hit_box.collision_mask = 2   # Detect player layer
    else:
        push_error("Hitbox not found! Make sure it's named 'Hitbox'")

func _physics_process(delta: float) -> void:
    match current_state:
        State.PATROL:
            patrol_behavior(delta)
        State.CHASE:
            chase_behavior(delta)
        State.ATTACK:
            attack_behavior(delta)
        State.DEATH:
            death_behavior(delta)
        State.RESPAWN:
            respawn_behavior(delta)
    
    # Apply shake effect when self-destructing
    if is_shaking and animated_sprite:
        shake_timer += delta
        if shake_timer < shake_duration:
            # Apply random shake offset
            animated_sprite.position = original_sprite_position + Vector2(
                randf_range(-shake_intensity, shake_intensity),
                randf_range(-shake_intensity, shake_intensity)
            )
        else:
            # Reset position and trigger explosion
            animated_sprite.position = original_sprite_position
            is_shaking = false
            trigger_death_animation()
    
    # Apply movement
    move_and_slide()

func patrol_behavior(delta: float) -> void:
    # Float around in a pattern
    float_timer += delta * float_frequency
    
    # Calculate a floating pattern using sine and cosine for smooth movement
    var offset_x = sin(float_timer) * float_radius
    var offset_y = cos(float_timer * 0.7) * (float_radius * 0.6)
    
    var target_position = home_position + Vector2(offset_x, offset_y)
    var direction = (target_position - global_position).normalized()
    
    velocity = direction * float_speed
    
    # Update animation
    if animated_sprite:
        if velocity.x > 0:
            animated_sprite.flip_h = false
        elif velocity.x < 0:
            animated_sprite.flip_h = true
        
        # Play idle animation if not already playing
        if animated_sprite.animation != "idle":
            animated_sprite.play("idle")

func chase_behavior(delta: float) -> void:
    # Safety check - make sure player reference is valid
    if player_ref == null or !is_instance_valid(player_ref):
        transition_to_state(State.PATROL)
        return
    
    # Get player position safely
    var player_position = player_ref.global_position
    var my_position = global_position
    
    # Calculate direction and velocity
    var direction = (player_position - my_position).normalized()
    velocity = direction * chase_speed
    
    # Update animation based on movement direction
    if animated_sprite:
        if velocity.x > 0:
            animated_sprite.flip_h = false
        elif velocity.x < 0:
            animated_sprite.flip_h = true
        
        # Continue playing idle animation while chasing
        if animated_sprite.animation != "idle":
            animated_sprite.play("idle")
    
    # Calculate distance to player
    var distance_to_player = my_position.distance_to(player_position)
    
    # If player gets too far, return to patrol
    if distance_to_player > detection_radius * 1.2:
        transition_to_state(State.PATROL)
    
    # If player is close enough, transition to attack
    if distance_to_player < 30:
        transition_to_state(State.ATTACK)

func attack_behavior(delta: float) -> void:
    # Enemy has reached the player and will self-destruct
    velocity = Vector2.ZERO
    
    # Start shaking before exploding
    if !is_shaking:
        is_shaking = true
        shake_timer = 0.0

func death_behavior(delta: float) -> void:
    # Death animation is playing, don't move
    velocity = Vector2.ZERO
    
    # Animation is handled by the trigger_death_animation function

func respawn_behavior(delta: float) -> void:
    # Count down respawn timer
    respawn_timer -= delta
    
    if respawn_timer <= 0:
        # Respawn the enemy
        global_position = original_position
        home_position = original_position
        
        # Reset collision
        if collision_shape:
            collision_shape.set_deferred("disabled", false)
        
        if hit_box:
            hit_box.set_deferred("monitoring", true)
        
        if detection_area:
            detection_area.set_deferred("monitoring", true)
        
        # Reset visual and state
        modulate.a = 1.0
        transition_to_state(State.PATROL)

func transition_to_state(new_state: State) -> void:
    # Exit actions for current state
    match current_state:
        State.DEATH:
            # Reset for respawn
            respawn_timer = respawn_time
    
    # Enter actions for new state
    match new_state:
        State.PATROL:
            player_ref = null
        State.ATTACK:
            velocity = Vector2.ZERO
        State.DEATH:
            # Handled by trigger_death_animation
            pass
        State.RESPAWN:
            # Make enemy invisible
            modulate.a = 0.0
            
            # Disable collisions while respawning
            if collision_shape:
                collision_shape.set_deferred("disabled", true)
            
            if hit_box:
                hit_box.set_deferred("monitoring", false)
            
            if detection_area:
                detection_area.set_deferred("monitoring", false)
    
    current_state = new_state

func trigger_death_animation() -> void:
    # Increase player score
    if "Global" in get_tree().root and "sparkysVanquished" in Global:
        Global.sparkysVanquished += value
        if Global.has_signal("update_score"):
            Global.update_score.emit()
    
    # Play death animation
    if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
        animated_sprite.play("death")
        
        # Wait for animation to finish, then start respawn
        await animated_sprite.animation_finished
        transition_to_state(State.RESPAWN)
    else:
        # No animation available, go straight to respawn
        transition_to_state(State.RESPAWN)

func take_damage() -> void:
    # This method is called when the player's attack hits the enemy
    # Only the hitbox area should trigger this, not the detection area
    if current_state != State.DEATH and current_state != State.RESPAWN:
        print("Enemy taking damage!")
        transition_to_state(State.DEATH)
        trigger_death_animation()

func _on_detection_area_body_entered(body: Node2D) -> void:
    # Only use the detection area for sensing the player, NOT for damage
    if body and body.is_in_group("player"):
        player_ref = body as CharacterBody2D
        if current_state == State.PATROL:
            transition_to_state(State.CHASE)

func _on_detection_area_body_exited(body: Node2D) -> void:
    if body and body.is_in_group("player") and body == player_ref:
        # Just transition to patrol if we were chasing
        if current_state == State.CHASE:
            transition_to_state(State.PATROL)

func _on_hit_box_body_entered(body: Node2D) -> void:
    if body and body.is_in_group("player") and current_state != State.DEATH and current_state != State.RESPAWN:
        # We hit the player, self-destruct
        transition_to_state(State.ATTACK)
        
        # If player has take_damage method, call it
        if body.has_method("take_damage"):
            body.take_damage()