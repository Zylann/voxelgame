# Container for all block types.
# It is not a resource because it references scripts that can depend on it,
# causing cycles. So instead, it's more convenient to make it a node in the tree.
# IMPORTANT: Needs to be first in tree. Other nodes may use it in _ready().
extends Node

const Block = preload("./block.gd")
const Util = preload("res://common/util.gd")

const ROTATION_TYPE_NONE = 0
const ROTATION_TYPE_AXIAL = 1
const ROTATION_TYPE_Y = 2
const ROTATION_TYPE_CUSTOM_BEHAVIOR = 3

const ROTATION_Y_NEGATIVE_X = 0
const ROTATION_Y_POSITIVE_X = 1
const ROTATION_Y_NEGATIVE_Z = 2
const ROTATION_Y_POSITIVE_Z = 3

const _opposite_y_rotation : Array[int] = [
	ROTATION_Y_POSITIVE_X,
	ROTATION_Y_NEGATIVE_X,
	ROTATION_Y_POSITIVE_Z,
	ROTATION_Y_NEGATIVE_Z
]

const _y_dir : Array[Vector3] = [
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 0, -1),
	Vector3(0, 0, 1)
]

const ROOT = "res://blocky_game/blocks"

const AIR_ID = 0

class RawMapping:
	var block_id := 0
	var variant_index := 0


var _voxel_library := preload("res://blocky_game/blocks/voxel_library.tres")
var _blocks = []
var _raw_mappings = []


func _init():
	print("Constructing blocks.gd")
	_create_block({
		"name": "air",
		"directory": "",
		"gui_model": "",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["air"],
		"transparent": true
	})
	_create_block({
		"name": "dirt",
		"gui_model": "dirt.obj",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["dirt"],
		"transparent": false
	})
	_create_block({
		"name": "grass",
		"gui_model": "grass.obj",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["grass"],
		"transparent": false
	})
	_create_block({
		"name": "log",
		"gui_model": "log_y.obj",
		"rotation_type": ROTATION_TYPE_AXIAL,
		"voxels": ["log_x", "log_y", "log_z"],
		"transparent": false
	})
	_create_block({
		"name": "planks",
		"gui_model": "planks.obj",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["planks"],
		"transparent": false
	})
	_create_block({
		"name": "stairs",
		"gui_model": "stairs_nx.obj",
		"rotation_type": ROTATION_TYPE_Y,
		"voxels": ["stairs_nx", "stairs_px", "stairs_nz", "stairs_pz"],
		"transparent": false
	})
	_create_block({
		"name": "tall_grass",
		"gui_model": "tall_grass.obj",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["tall_grass"],
		"transparent": true,
		"backface_culling": false
	})
	_create_block({
		"name": "glass",
		"gui_model": "glass.obj",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["glass"],
		"transparent": true,
		"backface_culling": true
	})
	_create_block({
		"name": "water",
		"gui_model": "water_full.obj",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["water_full", "water_top"],
		"transparent": true,
		"backface_culling": true
	})
	_create_block({
		"name": "rail",
		"gui_model": "rail_x.obj",
		"rotation_type": ROTATION_TYPE_CUSTOM_BEHAVIOR,
		"voxels": [
			# Order matters, see rail.gd
			"rail_x", "rail_z",
			"rail_turn_nx", "rail_turn_px", "rail_turn_nz", "rail_turn_pz",
			"rail_slope_nx", "rail_slope_px","rail_slope_nz", "rail_slope_pz"
		],
		"transparent": true,
		"backface_culling": true,
		"behavior": "rail.gd"
	})
	_create_block({
		"name": "leaves",
		"gui_model": "leaves.obj",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["leaves"],
		"transparent": true
	})
	_create_block({
		"name": "dead_shrub",
		"gui_model": "dead_shrub.obj",
		"rotation_type": ROTATION_TYPE_NONE,
		"voxels": ["dead_shrub"],
		"transparent": true,
		"backface_culling": false
	})


func get_block(id: int) -> Block:
	assert(id >= 0)
	return _blocks[id]


func get_model_library() -> VoxelBlockyLibrary:
	return _voxel_library


func get_block_by_name(block_name: String) -> Block:
	for b in _blocks:
		if b.base_info.name == block_name:
			return b
	assert(false)
	return null


# Gets the corresponding block ID and variant index from a raw voxel value
func get_raw_mapping(raw_id: int) -> RawMapping:
	assert(raw_id >= 0)
	var rm = _raw_mappings[raw_id]
	assert(rm != null)
	return rm


func get_block_count() -> int:
	return len(_blocks)


func _create_block(params: Dictionary):
	_defaults(params, {
		"rotation_type": ROTATION_TYPE_NONE,
		"transparent": false,
		"backface_culling": true,
		"directory": params.name,
		"behavior": ""
	})

	var block : Block
	if params.behavior != "":
		# Block with special behavior
		var behavior_path := str(ROOT, "/", params.directory, "/", params.behavior)
		var behavior = load(behavior_path)
		block = behavior.new()
	else:
		# Generic
		block = Block.new()

	# Fill in base info
	var base_info := block.base_info
	base_info.id = len(_blocks)
	
	for i in len(params.voxels):
		var vname : String = params.voxels[i]
		var id := _voxel_library.get_model_index_from_resource_name(vname)
		if id == -1:
			push_error("Could not find voxel named {0}".format([vname]))
		assert(id != -1)
		params.voxels[i] = id
		var rm := RawMapping.new()
		rm.block_id = base_info.id
		rm.variant_index = i
		if id >= len(_raw_mappings):
			_raw_mappings.resize(id + 1)
		_raw_mappings[id] = rm

	base_info.name = params.name
	base_info.directory = params.directory
	base_info.rotation_type = params.rotation_type
	base_info.voxels = params.voxels
	base_info.transparent = params.transparent
	base_info.backface_culling = params.backface_culling
	if base_info.directory != "":
		base_info.gui_model_path = str(ROOT, "/", params.directory, "/", params.gui_model)
		var sprite_path := str(ROOT, "/", params.directory, "/", params.name, "_sprite.png")
		base_info.sprite_texture = load(sprite_path)

	_blocks.append(block)
	add_child(block)


func _notification(what):
	match what:
		NOTIFICATION_PREDELETE:
			print("Deleting blocks.gd")


static func _defaults(d: Dictionary, defaults: Dictionary):
	for k in defaults:
		if not d.has(k):
			d[k] = defaults[k]


static func get_y_rotation_from_look_dir(dir: Vector3) -> int:
	var a = Util.get_direction_id4(Vector2(dir.x, dir.z))
	match a:
		0:
			return ROTATION_Y_NEGATIVE_X
		1:
			return ROTATION_Y_NEGATIVE_Z
		2:
			return ROTATION_Y_POSITIVE_X
		3:
			return ROTATION_Y_POSITIVE_Z
		_:
			assert(false)
	return -1


static func get_y_dir_vec(yid: int) -> Vector3:
	return _y_dir[yid]


static func get_opposite_y_dir(yid: int) -> int:
	return _opposite_y_rotation[yid]
