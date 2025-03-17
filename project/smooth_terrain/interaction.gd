extends Node

const SDFStamper = preload("./sdf_stamper.gd")
const VoxelVersion = preload("res://addons/zylann.voxel/version.gd")

@onready var _head : Node3D = get_parent().get_node("Camera")
@onready var _terrain : VoxelLodTerrain = get_parent().get_parent().get_node("VoxelTerrain")
@onready var _sdf_stamper : SDFStamper = get_parent().get_node("SdfStamper")

const MODE_SPHERES = 0
const MODE_MESHES = 1

var _action_place := false
var _action_remove := false
var _mode := MODE_SPHERES
var _radius := 6.0


func _ready():
	_sdf_stamper.set_terrain(_terrain)


func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				_action_place = true
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				_action_remove = true
	
	elif event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_1:
				_set_mode(MODE_SPHERES)
			elif event.keycode == KEY_2:
				_set_mode(MODE_MESHES)
			elif event.keycode == KEY_KP_ADD:
				_radius += 0.1
				print("radius: ", _radius)
			elif event.keycode == KEY_KP_SUBTRACT:
				_radius = maxf(_radius - 0.1, 0.1)
				print("radius: ", _radius)


func _set_mode(mode: int):
	if mode != _mode:
		print("Set mode ", mode)
		_mode = mode
		_sdf_stamper.set_active(_mode == MODE_MESHES)


func _process(delta: float):
	var head_trans := _head.global_transform
	var pointed_pos := head_trans.origin - 12.0 * head_trans.basis.z

	if _mode == MODE_SPHERES:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_action_place = true
		
		if _action_place:
			do_sphere(pointed_pos, _radius, true)
		elif _action_remove:
			do_sphere(pointed_pos, _radius, false)
	
	elif _mode == MODE_MESHES:
		if _action_place:
			_sdf_stamper.place()

	_action_place = false
	_action_remove = false


func do_sphere(center: Vector3, radius: float, add: bool):
	var vt := _terrain.get_voxel_tool()
	if add:
		vt.mode = VoxelTool.MODE_ADD
	else:
		vt.mode = VoxelTool.MODE_REMOVE

	if VoxelVersion.get_major() == 1 and VoxelVersion.get_minor() == 1:
		# Version prior to 1.2 did not expose consistent SDF due to internal quantization,
		# so scaling had to be done by the user
		vt.set_sdf_scale(0.002)

	vt.do_sphere(center, radius)
