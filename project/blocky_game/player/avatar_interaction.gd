extends Node

const Util = preload("res://common/util.gd")
const Blocks = preload("../blocks/blocks.gd")
const ItemDB = preload("../items/item_db.gd")
const InventoryItem = preload("./inventory_item.gd")
const Hotbar = preload("../gui/hotbar/hotbar.gd")

const COLLISION_LAYER_AVATAR = 2

const _hotbar_keys = {
	KEY_1: 0,
	KEY_2: 1,
	KEY_3: 2,
	KEY_4: 3,
	KEY_5: 4,
	KEY_6: 5,
	KEY_7: 6,
	KEY_8: 7,
	KEY_9: 8
}

export(NodePath) var terrain_path = null
export(Material) var cursor_material = null

# TODO Eventually invert these dependencies
onready var _head : Camera = get_parent().get_node("Camera")
onready var _hotbar : Hotbar = get_node("../HotBar")
onready var _block_types : Blocks = get_node("/root/Main/Blocks")
onready var _item_db : ItemDB = get_node("/root/Main/Items")
onready var _water_updater = get_node("../../Water")

var _terrain = null
var _terrain_tool = null
var _cursor = null
var _action_place = false
var _action_use = false
var _action_pick = false


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
	_terrain_tool.channel = VoxelBuffer.CHANNEL_TYPE


func _get_pointed_voxel():
	var origin = _head.get_global_transform().origin
	var forward = -_head.get_transform().basis.z.normalized()
	var hit = _terrain_tool.raycast(origin, forward, 10)
	return hit


func _physics_process(_delta):
	if _terrain == null:
		return
	
	var hit = _get_pointed_voxel()
	if hit != null:
		_cursor.show()
		_cursor.set_translation(hit.position)
		DDD.set_text("Pointed voxel", str(hit.position))
	else:
		_cursor.hide()
		DDD.set_text("Pointed voxel", "---")

	var inv_item := _hotbar.get_selected_item()
	
	# These inputs have to be in _fixed_process because they rely on collision queries
	if inv_item == null or inv_item.type == InventoryItem.TYPE_BLOCK:
		if hit != null:
			var hit_raw_id = _terrain_tool.get_voxel(hit.position)
			var has_cube = hit_raw_id != 0
			
			if _action_use and has_cube:
				var pos = hit.position
				_place_single_block(pos, 0)
			
			elif _action_place:
				var pos = hit.previous_position
				if has_cube == false:
					pos = hit.position
				if _can_place_voxel_at(pos):
					if inv_item != null:
						_place_single_block(pos, inv_item.id)
						print("Place voxel at ", pos)
				else:
					print("Can't place here!")
				
	elif inv_item.type == InventoryItem.TYPE_ITEM:
		if _action_use:
			var item = _item_db.get_item(inv_item.id)
			item.use(_head.global_transform)
	
	if _action_pick and hit != null:
		var hit_raw_id = _terrain_tool.get_voxel(hit.position)
		var rm := _block_types.get_raw_mapping(hit_raw_id)
		_hotbar.try_select_slot_by_block_id(rm.block_id)

	_action_place = false
	_action_use = false
	_action_pick = false


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				BUTTON_LEFT:
					_action_use = true
				BUTTON_RIGHT:
					_action_place = true
				BUTTON_MIDDLE:
					_action_pick = true
				BUTTON_WHEEL_DOWN:
					_hotbar.select_next_slot()
				BUTTON_WHEEL_UP:
					_hotbar.select_previous_slot()

	elif event is InputEventKey:
		if event.pressed:
			if _hotbar_keys.has(event.scancode):
				var slot_index = _hotbar_keys[event.scancode]
				_hotbar.select_slot(slot_index)


func _can_place_voxel_at(pos: Vector3):
	# TODO Is it really relevant anymore? This demo doesn't use physics
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


func _place_single_block(pos: Vector3, block_id: int):
	var block := _block_types.get_block(block_id)
	var voxel_id := 0
	var look_dir := -_head.get_transform().basis.z

	match block.base_info.rotation_type:
		Blocks.ROTATION_TYPE_NONE:
			voxel_id = block.base_info.voxels[0]
		
		Blocks.ROTATION_TYPE_AXIAL:
			var axis := Util.get_longest_axis(look_dir)
			voxel_id = block.base_info.voxels[axis]
		
		Blocks.ROTATION_TYPE_Y:
			var rot := Blocks.get_y_rotation_from_look_dir(look_dir)
			voxel_id = block.base_info.voxels[rot]

		Blocks.ROTATION_TYPE_CUSTOM_BEHAVIOR:
			block.place(_terrain_tool, pos, look_dir)
		_:
			# Unknown value
			assert(false)
	
	if block.base_info.rotation_type != Blocks.ROTATION_TYPE_CUSTOM_BEHAVIOR:
		_place_single_voxel(pos, voxel_id)
	
	_water_updater.schedule(pos)


func _place_single_voxel(pos: Vector3, type: int):
	_terrain_tool.value = type
	_terrain_tool.do_point(pos)

