extends Node

const Util = preload("res://common/util.gd")
const Blocks = preload("../blocks/blocks.gd")
const WaterUpdater = preload("./../water.gd")
const InteractionCommon = preload("./interaction_common.gd")

@export var terrain_path : NodePath

@onready var _block_types : Blocks = get_node("/root/Main/Game/Blocks")
@onready var _water_updater : WaterUpdater
@onready var _terrain : VoxelTerrain = get_node("/root/Main/Game/VoxelTerrain")

var _terrain_tool : VoxelTool = null


func _ready():
	_terrain_tool = _terrain.get_voxel_tool()
	_terrain_tool.channel = VoxelBuffer.CHANNEL_TYPE

	var mp := get_tree().get_multiplayer()
	if mp.has_multiplayer_peer() == false or mp.is_server():
		_water_updater = get_node("/root/Main/Game/Water")


# Actually, we only want this to be called from clients to the server! Not any peer!
# But that specification doesn't exist in the API.
@rpc("any_peer", "call_remote", "reliable", 0)
func receive_place_single_block(pos: Vector3, look_dir: Vector3, block_id: int):
	InteractionCommon.place_single_block(_terrain_tool, pos, look_dir, block_id, _block_types, 
		_water_updater)
