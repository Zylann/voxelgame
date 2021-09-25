extends Node

onready var _head = get_parent().get_node("Camera")
onready var _terrain = get_parent().get_parent().get_node("VoxelTerrain")

var _action_place = false
var _action_remove = false


func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				_action_place = true
			elif event.button_index == BUTTON_RIGHT:
				_action_remove = true


func _process(delta):
	var head_trans = _head.global_transform
	var pointed_pos = head_trans.origin - 6.0 * head_trans.basis.z

	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		_action_remove = true

	if _action_place:
		do_sphere(pointed_pos, 3.5, true)
	elif _action_remove:
		do_sphere(pointed_pos, 3.5, false)

	_action_place = false
	_action_remove = false


func do_sphere(center, fradius, add):
	var vt = _terrain.get_voxel_tool()
	if add:
		vt.mode = VoxelTool.MODE_ADD
	else:
		vt.mode = VoxelTool.MODE_REMOVE
	vt.set_sdf_scale(0.1)
	vt.do_sphere(center, fradius)

