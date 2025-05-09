# Improved Flying Enemy Instructions

I've created an improved flying enemy script that implements patrol, self-destruct, and respawn behaviors as requested. Here's how to use it:

## Setup Instructions

1. **Use the new script**:
   - Open your FlyingEnemy scene in Godot
   - In the Inspector panel, change the script from `sparky.gd` to `sparky_improved.gd`

2. **Configure parameters** (optional):
   - `float_speed`: How fast the enemy floats during patrol (default: 40)
   - `chase_speed`: How fast the enemy chases the player (default: 150)
   - `detection_radius`: How far the enemy can detect the player (default: 200)
   - `float_radius`: How far the enemy floats from its home position (default: 50)
   - `respawn_time`: How long it takes for the enemy to respawn (default: 3 seconds)
   - `shake_intensity`: How much the enemy shakes before exploding (default: 5)
   - `shake_duration`: How long the enemy shakes before exploding (default: 0.5 seconds)

## New Behaviors

The improved enemy now has these behaviors:

1. **Patrol Behavior**:
   - Enemy floats around in a sine-wave pattern when no player is detected
   - Stays within a certain radius of its home position

2. **Chase Behavior**:
   - When player enters detection radius, enemy chases them
   - If player gets too far, enemy returns to patrol

3. **Attack Behavior**:
   - When enemy reaches the player, it will shake (self-destruct sequence)
   - After shaking, it plays the explosion/death animation
   - Damages the player on contact

4. **Death & Respawn**:
   - When the enemy is attacked by player or self-destructs
   - Plays death animation with puff of smoke
   - Becomes invisible during respawn period
   - Reappears at original position after respawn timer completes

## Animation Requirements

The script requires these animations in your AnimatedSprite2D:

1. `idle`: Normal floating animation
2. `death`: Explosion/puff of smoke animation (should be non-looping)

## Technical Details

- Uses a state machine pattern for cleaner behavior management
- Properly handles collision enabling/disabling during different states
- Includes visual effects like shaking before exploding
- Updates the global score counter when destroyed

## Behavior Flow

1. Enemy spawns in PATROL state and moves in a pattern
2. When player is detected, transitions to CHASE state
3. If enemy touches player, transitions to ATTACK state:
   - Enemy shakes for a moment (build up)
   - Then plays death animation and damages player
4. After death animation completes, transitions to RESPAWN state
5. After respawn timer completes, returns to original position and PATROL state

Let me know if you need any adjustments to the behaviors or parameters!