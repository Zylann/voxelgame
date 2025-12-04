Changelog
=============


0.2 
----

Uses Godot 4 from this version.

- Added `draw_cube`
- Added `draw_transformed_cube`
- Added `draw_axes`
- Added `draw_mesh`
- Cubes and boxes are now centered
- A monospace font is now used instead of Godot's default font
- Fix 2D drawing order if the game uses multiple `CanvasLayer` (thanks AheadGameStudio)
- Fix leak in headless mode where shapes were never cleared due to the frame counter never increasing


0.1
-----

Initial version

- Functions to display text as a HUD
- Functions to draw 3D lines
- Functions to draw 3D boxes
