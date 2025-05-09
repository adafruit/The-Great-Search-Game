# Improved Camera Limit Area

I've created an enhanced version of your CameraLimitArea with several new features and improvements. This document explains how to use it.

## Key Improvements

1. **Auto-sized Camera Limits** - Automatically calculate limits from collision shape
2. **Camera Mode Control** - Override the camera's follow mode when entering the area
3. **Camera Zoom Control** - Smoothly adjust camera zoom when entering the area
4. **Transition Options** - More control over how transitions happen
5. **Better Visualization** - Improved debug visualization
6. **Manual Control** - Methods to manually activate/deactivate the area
7. **More Robust** - Better error handling and node detection

## Setup Instructions

1. Open your project in Godot
2. Create a new CameraLimitArea scene or edit an existing one
3. Attach the new `camera_limit_area_improved.gd` script
4. Configure the parameters as needed

## Parameters

### Camera Limits
- `left_limit`, `right_limit`, `top_limit`, `bottom_limit` - The camera limits to apply
- `auto_size_from_shape` - Automatically calculate limits from collision shape (overrides manual limits)

### Transition Settings
- `transition_time` - How long the transition takes (seconds)
- `transition_type` - Tween transition type (QUAD, CUBIC, etc.)
- `ease_type` - Tween easing (IN, OUT, IN_OUT)

### Camera Behavior
- `override_camera_follow` - Whether to change the camera's follow mode
- `camera_follow_mode` - The mode to set (true = follow player, false = room-based)
- `restore_camera_mode` - Whether to restore original mode on exit

### Zoom Settings
- `override_zoom` - Whether to change camera zoom
- `target_zoom` - The zoom to apply
- `zoom_transition_time` - How long the zoom transition takes

### Visual Settings
- `debug_color` - Color of the debug visualization
- `show_debug` - Whether to show debug visualization

## Usage Examples

### Basic Room Limit
```gdscript
# Just set auto_size_from_shape = true
# The script will automatically calculate limits from your collision shape
```

### Zoom-Out Area
```gdscript
# Override zoom but maintain limits
override_zoom = true
target_zoom = Vector2(0.8, 0.8)  # Zoom out to see more
zoom_transition_time = 0.5
```

### Free-Roam Area
```gdscript
# Override camera mode to follow player
override_camera_follow = true
camera_follow_mode = true  # Follow player
restore_camera_mode = true  # Restore previous mode on exit
```

### Boss Arena
```gdscript
# Limit camera, zoom out, and enable free movement
auto_size_from_shape = true
override_camera_follow = true
camera_follow_mode = true
override_zoom = true
target_zoom = Vector2(0.7, 0.7)
```

## Advanced Features

### Manual Control
You can manually trigger the area from code:
```gdscript
# Get a reference to your area
var camera_area = $CameraLimitArea

# Manually activate
camera_area.activate()

# Manually deactivate
camera_area.deactivate()

# Update limits if shape changed
camera_area.update_limits()
```

### Compatibility
The script is designed to work with different camera implementations:
- Works with cameras in the "main_camera" group
- Falls back to finding any Camera2D
- Handles both method calls and direct property access

## Tips and Best Practices

1. **Use Auto-Sizing**: Enable `auto_size_from_shape` to automatically calculate limits from your collision shape.

2. **Camera Groups**: Add your camera to the "main_camera" group for better compatibility.

3. **Debugging**: Enable `show_debug` to visualize the area and limits during development.

4. **Transitions**: Adjust transition and ease types for different effects:
   - QUAD/CUBIC with EASE_OUT for smooth natural transitions
   - BOUNCE with EASE_OUT for a slight bounce effect
   - CIRC with EASE_IN_OUT for a cinematic feel

5. **Camera Modes**: Use `override_camera_follow` to create areas where the camera follows the player freely (like boss arenas).

6. **Zoom Effects**: Create interesting zoom effects for different areas of your game.

7. **Layer Configuration**: Place your CameraLimitArea on a collision layer that only interacts with the player.

## Troubleshooting

- **Camera Limits Not Working**: Make sure your camera is in the "main_camera" group, or the script will try to find it automatically.

- **Jittery Transitions**: Increase the transition time for smoother effects.

- **Limits Don't Match Shape**: Ensure `auto_size_from_shape` is enabled, or set limits manually.

- **Camera Mode Not Changing**: Check if your camera script has `follow_player` property or a `set_follow_player()` method.

Enjoy your improved camera limits!
