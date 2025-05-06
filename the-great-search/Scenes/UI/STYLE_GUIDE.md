# In-Game Menu Style Guide

## Color Scheme

Based on your existing game style, here's a recommended color scheme:

- Background: `Color(0.619608, 0.0745098, 0.364706, 0.721569)` (the pinkish-purple with transparency)
- Text: White or light gray for good contrast
- Button Normal: Dark purple `Color(0.4, 0.05, 0.25, 1.0)`
- Button Hover: Slightly lighter purple `Color(0.5, 0.06, 0.3, 1.0)`
- Button Pressed: Even lighter `Color(0.6, 0.07, 0.35, 1.0)`

## Fonts

Continue using your PressStart2P font for consistency:
- Title: 42px
- Button Text: 32px 
- Settings Labels: 24px

## Menu Layout

### Pause Menu
- Title "PAUSED" at the top
- Center all elements
- Buttons stacked vertically with some spacing
- Semi-transparent background to see the game world behind

### Settings Panel
- Sound volume slider
- Music volume slider
- Fullscreen toggle
- Back button to return to pause menu

## Button Styling

- Rectangular buttons with slight rounding
- Consistent padding (at least 10px on all sides)
- Text centered in buttons
- Clear hover state (change color or add a subtle outline)

## Animation

Consider adding these subtle animations:
- Fade in/out when opening/closing menus (0.2-0.3 seconds)
- Slight scale effect on button hover
- Button press effect (slight shrink when clicked)

## Consistency

- Maintain consistent spacing between elements
- Align all elements properly
- Use the same style for all UI elements
- Keep the menu simple and uncluttered

## Mobile Considerations

If your game supports mobile:
- Make buttons larger for touch input
- Consider adding a visible close/back button
- Test UI scaling on different screen sizes