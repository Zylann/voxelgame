Voxel game demos (Godot Engine 4.3)
====================================

This project contains several scenes to test and demo the voxel module I'm developing for Godot Engine.

![Screenshot](screenshots/2020_05_05_1953_small.png)


Dependencies
---------------

This project uses a C++ module:
- [Voxel](https://github.com/Zylann/godot_voxel)

For the old (unmaintained) pure-GDScript version, checkout the branch `full_gdscript`.


Runnable scenes
-----------------

- `blocky_game/main.tscn`: sort of Minecraft clone with random features.
- `blocky_terrain/main.tscn`: simple test for blocky terrain
- `smooth_terrain/main.tscn`: simple test for Transvoxel smooth terrain


Blocky Game
------------

This game is a demo meant to be a practical example of using `VoxelTerrain` with a blocky look. It is not complete, some features might be incomplete, but it doesn't aim to be a finished game.

It can be played in multiplayer. You can either host a game, join a game, or play without multiplayer.
Synchronization is very basic: players are authoritative of their physics, but voxels are sent by the server, and edited on the server.
