extends Node

const Util = preload("res://common/util.gd")
const Blocks = preload("../blocks/blocks.gd")
const ItemDB = preload("../items/item_db.gd")
const InventoryItem = preload("./inventory_item.gd")
const Hotbar = preload("../gui/hotbar/hotbar.gd")
const WaterUpdater = preload("./../water.gd")
const InteractionCommon = preload("./interaction_common.gd")

const COLLISION_LAYER_AVATAR = 2
const SERVER_PEER_ID = 1

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

@export var terrain_path : NodePath
@export var cursor_material : Material

# TODO Eventually invert these dependencies
@onready var _head : Camera3D = get_parent().get_node("Camera")
@onready var _hotbar : Hotbar = get_node("../HotBar")
@onready var _block_types : Blocks = get_node("/root/Main/Game/Blocks")
@onready var _item_db : ItemDB = get_node("/root/Main/Game/Items")
@onready var _water_updater : WaterUpdater
@onready var _terrain : VoxelTerrain = get_node("/root/Main/Game/VoxelTerrain")

var _terrain_tool : VoxelTool = null
var _cursor : MeshInstance3D = null
var _action_place := false
var _action_use := false
var _action_pick := false


func _ready():
	var mesh := Util.create_wirecube_mesh(Color(0,0,0))
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	if cursor_material != null:
		mesh_instance.material_override = cursor_material
	mesh_instance.set_scale(Vector3(1,1,1)*1.01)
	_cursor = mesh_instance
	
	_terrain.add_child(_cursor)
	_terrain_tool = _terrain.get_voxel_tool()
	_terrain_tool.channel = VoxelBuffer.CHANNEL_TYPE

	var mp := get_tree().get_multiplayer()
	if mp.has_multiplayer_peer() == false or mp.is_server():
		_water_updater = get_node("/root/Main/Game/Water")


func _get_pointed_voxel() -> VoxelRaycastResult:
	var origin := _head.get_global_transform().origin
	assert(not Util.vec3_has_nan(origin))
	var forward := -_head.get_transform().basis.z.normalized()
	var hit := _terrain_tool.raycast(origin, forward, 10)
	return hit


func _physics_process(_delta):
	if _terrain == null:
		return
	
	var hit := _get_pointed_voxel()
	if hit != null:
		_cursor.show()
		_cursor.set_position(hit.position)
		DDD.set_text("Pointed voxel", str(hit.position))
	else:
		_cursor.hide()
		DDD.set_text("Pointed voxel", "---")

	var inv_item := _hotbar.get_selected_item()
	
	# These inputs have to be in _fixed_process because they rely on collision queries
	if inv_item == null or inv_item.type == InventoryItem.TYPE_BLOCK:
		if hit != null:
			var hit_raw_id := _terrain_tool.get_voxel(hit.position)
			var has_cube := hit_raw_id != 0
			
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


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					_action_use = true
				MOUSE_BUTTON_RIGHT:
					_action_place = true
				MOUSE_BUTTON_MIDDLE:
					_action_pick = true
				MOUSE_BUTTON_WHEEL_DOWN:
					_hotbar.select_next_slot()
				MOUSE_BUTTON_WHEEL_UP:
					_hotbar.select_previous_slot()

	elif event is InputEventKey:
		if event.pressed:
			if _hotbar_keys.has(event.keycode):
				var slot_index = _hotbar_keys[event.keycode]
				_hotbar.select_slot(slot_index)


func _can_place_voxel_at(pos: Vector3):
	# TODO Is it really relevant anymore? This demo doesn't use physics
	var space_state := get_viewport().get_world_3d().get_direct_space_state()
	var params := PhysicsShapeQueryParameters3D.new()
	params.collision_mask = COLLISION_LAYER_AVATAR
	params.transform = Transform3D(Basis(), pos + Vector3(1,1,1)*0.5)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1, 1, 1)
	params.set_shape(shape)
	var hits := space_state.intersect_shape(params)
	return hits.size() == 0


func _place_single_block(pos: Vector3, block_id: int):
	var look_dir := -_head.get_transform().basis.z
	var mp := get_tree().get_multiplayer()
	if mp.has_multiplayer_peer() and not mp.is_server():
		rpc_id(SERVER_PEER_ID, &"receive_place_single_block", pos, look_dir, block_id)
	else:
		InteractionCommon.place_single_block(_terrain_tool, pos, look_dir,
			block_id, _block_types, _water_updater)


# TODO Maybe use `rpc_config` so this would be less awkward?
@rpc("any_peer", "call_remote", "reliable", 0)
func receive_place_single_block(pos: Vector3, look_dir: Vector3, block_id: int):
	# The server has a different script for remote players
	push_error("Didn't expect this method to be called")

