extends Node

const Util = preload("res://common/util.gd")

const COLLISION_LAYER_AVATAR = 2

export(NodePath) var terrain_path = null
export(Material) var cursor_material = null

onready var _light = get_node("../../DirectionalLight") # For debug shadow toggle
onready var _head = get_parent().get_node("Camera")

var _terrain = null
var _terrain_tool = null
var _cursor = null
var _action_place = false
var _action_remove = false

var _inventory = [1, 2]
var _inventory_index = 0


func _ready():
	if terrain_path == null:
		_terrain = get_parent().get_node(get_parent().terrain)
		terrain_path = _terrain.get_path() # For correctness
	else:
		_terrain = get_node(terrain_path)
	
	var mesh = Util.create_wirecube_mesh(Color(0,0,0))
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = mesh
	if cursor_material != null:
		mesh_instance.material_override = cursor_material
	mesh_instance.set_scale(Vector3(1,1,1)*1.01)
	_cursor = mesh_instance
	
	_terrain.add_child(_cursor)
	_terrain_tool = _terrain.get_voxel_tool()


func get_pointed_voxel():
	var origin = _head.get_global_transform().origin
	var forward = -_head.get_transform().basis.z.normalized()
	var hit = _terrain_tool.raycast(origin, forward, 10)
	return hit


func _physics_process(delta):
	if _terrain == null:
		return
	
	var hit = get_pointed_voxel()
	if hit != null:
		_cursor.show()
		_cursor.set_translation(hit.position)
		get_parent().get_node("debug_label").text = str(hit.position)
	else:
		_cursor.hide()
		get_parent().get_node("debug_label").text = "---"
	
	# These inputs have to be in _fixed_process because they rely on collision queries
	if hit != null:
		var has_cube = _terrain_tool.get_voxel(hit.position) != 0
		
		if _action_place and has_cube:
			var pos = hit.position
			do_sphere(pos, 5, 0)
		
		elif _action_remove:
			var pos = hit.previous_position
			if has_cube == false:
				pos = hit.position
			if can_place_voxel_at(pos):
				do_sphere(pos, 4, _inventory[_inventory_index])
				print("Place voxel at ", pos)
			else:
				print("Can't place here!")

	_action_place = false
	_action_remove = false


func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					_action_place = true
				BUTTON_RIGHT:
					_action_remove = true

	elif event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_1:
					select_inventory(0)
				KEY_2:
					select_inventory(1)
				KEY_L:
					_light.shadow_enabled = not _light.shadow_enabled


func select_inventory(i):
	if i < 0 or i >= len(_inventory):
		return
	_inventory_index = i
	var vi = _inventory[i]
	print("Inventory select ", _terrain.voxel_library.get_voxel(vi).voxel_name, " (", vi, ")")


func can_place_voxel_at(pos):
	var space_state = get_viewport().get_world().get_direct_space_state()
	var params = PhysicsShapeQueryParameters.new()
	params.collision_mask = COLLISION_LAYER_AVATAR
	params.transform = Transform(Basis(), pos + Vector3(1,1,1)*0.5)
	var shape = BoxShape.new()
	var ex = 0.5
	shape.extents = Vector3(ex, ex, ex)
	params.set_shape(shape)
	var hits = space_state.intersect_shape(params)
	return hits.size() == 0


func do_sphere(center, r, type):
	_terrain_tool.channel = VoxelBuffer.CHANNEL_TYPE
	_terrain_tool.value = type
	_terrain_tool.do_point(center)

