# In-Game Menu Integration Guide

This guide explains how to integrate the in-game pause menu into your Great Search Game.

## Setup Steps

### 1. Add Autoload Singletons

In Project Settings > Autoload, add these singletons:

- Name: InputManager - Path: res://Scenes/UI/input_manager.gd
- Name: SettingsManager - Path: res://Scenes/UI/settings_manager.gd

### 2. Create Audio Buses

In Project Settings > Audio:
- Create a "Sound" bus for sound effects
- Create a "Music" bus for music
- Default bus will be renamed to "Master"

### 3. Create the Pause Menu Scene

1. Open Godot Editor
2. Create a new scene with CanvasLayer as root node
3. Follow the structure in `pause_menu_structure.txt`
4. Attach the `pause_menu.gd` script to the root node
5. Save the scene as `pause_menu.tscn`

### 4. Integrate the Pause Menu into Gameplay

Add this code to your main gameplay scene:

```gdscript
# In your main gameplay scene script
func _ready() -> void:
    # Connect to the input manager's pause signal
    InputManager.pause_requested.connect(_on_pause_requested)
    
    # Load the pause menu scene
    var pause_menu = load("res://Scenes/UI/pause_menu.tscn").instantiate()
    add_child(pause_menu)

func _on_pause_requested() -> void:
    # Find the pause menu node and toggle it
    var pause_menu = get_node("PauseMenu")
    if pause_menu:
        pause_menu.toggle_pause_menu()
```

### 5. Input Mappings

Make sure these inputs are properly mapped in Project Settings > Input Map:
- ui_cancel (usually mapped to ESC key)
- startOrMenu (for controller Start button)

## Testing

1. Run your game
2. Press ESC (or Start on controller) to open the pause menu
3. Verify the game pauses correctly
4. Test all menu buttons

## Audio Bus Setup

For the volume sliders to work correctly, make sure you have set up these audio buses:
- Sound (for sound effects)
- Music (for music)

If your project uses different bus names, update the `settings_manager.gd` script accordingly.

## Customization

Feel free to customize the UI appearance to match your game's style:
- Change fonts, colors, and button styles
- Add game-specific settings options
- Add animation for menu transitions