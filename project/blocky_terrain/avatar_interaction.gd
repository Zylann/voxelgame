extends Node

const Util = preload("res://common/util.gd")

const COLLISION_LAYER_AVATAR = 2

@export var terrain_path : NodePath
@export var cursor_material : Material

@onready var _head : Node3D = get_parent().get_node("Camera")

var _terrain : VoxelTerrain = null
var _terrain_tool = null
var _cursor = null
var _action_place := false
var _action_remove := false

var _inventory := [1, 2]
var _inventory_index := 0


func _ready():
	if terrain_path == NodePath():
		_terrain = get_parent().get_node(get_parent().terrain)
		terrain_path = _terrain.get_path() # For correctness
	else:
		_terrain = get_node(terrain_path)
	
	var mesh = Util.create_wirecube_mesh(Color(0,0,0))
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	if cursor_material != null:
		mesh_instance.material_override = cursor_material
	mesh_instance.set_scale(Vector3(1,1,1)*1.01)
	_cursor = mesh_instance
	
	_terrain.add_child(_cursor)
	_terrain_tool = _terrain.get_voxel_tool()


func get_pointed_voxel() -> VoxelRaycastResult:
	var origin = _head.get_global_transform().origin
	var forward = -_head.get_transform().basis.z.normalized()
	var hit = _terrain_tool.raycast(origin, forward, 10)
	return hit


func _physics_process(_delta):
	if _terrain == null:
		return
	
	var hit := get_pointed_voxel()
	if hit != null:
		_cursor.show()
		_cursor.set_position(hit.position)
		DDD.set_text("Pointed voxel", str(hit.position))
	else:
		_cursor.hide()
		DDD.set_text("Pointed voxel", "---")
	
	# These inputs have to be in _fixed_process because they rely on collision queries
	if hit != null:
		if _action_place:
			var pos = hit.previous_position
			if can_place_voxel_at(pos):
				place(pos)
		
		elif _action_remove:
			dig(hit.position)

	_action_place = false
	_action_remove = false


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_action_remove = true
				MOUSE_BUTTON_RIGHT:
					_action_place = true

	elif event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_1:
					select_inventory(0)
				KEY_2:
					select_inventory(1)


func select_inventory(i: int):
	if i < 0 or i >= len(_inventory):
		return
	_inventory_index = i
	var vi = _inventory[i]
	var lib = _terrain.mesher.library
	print("Inventory select ", lib.get_model(vi).resource_name, " (", vi, ")")


func can_place_voxel_at(pos: Vector3i):
	var space_state = get_viewport().get_world_3d().get_direct_space_state()
	var params = PhysicsShapeQueryParameters3D.new()
	params.collision_mask = COLLISION_LAYER_AVATAR
	params.transform = Transform3D(Basis(), Vector3(pos + Vector3i(1,1,1)) * 0.5)
	var shape = BoxShape3D.new()
	var ex = 0.5
	shape.extents = Vector3(ex, ex, ex)
	params.set_shape(shape)
	var hits = space_state.intersect_shape(params)
	return hits.size() == 0


func place(center: Vector3i):
	var type : int = _inventory[_inventory_index]
	_terrain_tool.channel = VoxelBuffer.CHANNEL_TYPE
	_terrain_tool.value = type
	if type == 1:
		_terrain_tool.do_point(center)
	else:
		_terrain_tool.do_sphere(center, 3)


func dig(center: Vector3i):
	var type : int = _inventory[_inventory_index]
	_terrain_tool.channel = VoxelBuffer.CHANNEL_TYPE
	_terrain_tool.value = 0
	if type == 1:
		_terrain_tool.do_point(center)
	else:
		_terrain_tool.do_sphere(center, 3)
