extends Node

@onready var _light : DirectionalLight3D = $DirectionalLight3D
@onready var _terrain : VoxelTerrain = $VoxelTerrain
@onready var _characters_container = $Players


func get_terrain() -> VoxelTerrain:
	return _terrain


func _unhandled_input(event: InputEvent):
	# TODO Make a pause menu with options?
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_L:
				# Toggle shadows
				_light.shadow_enabled = not _light.shadow_enabled
#			if event.keycode == KEY_KP_0:
#				# Force save
#				_save_world()


func _notification(what: int):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			# Save game when the user closes the window
			_save_world()


func _save_world():
	_terrain.save_modified_blocks()


func add_character(character: Node3D):
	_characters_container.add_child(character)

