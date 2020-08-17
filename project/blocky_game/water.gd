extends Node

const Blocks = preload("./blocks/blocks.gd")

const MAX_UPDATES_PER_FRAME = 64
const INTERVAL_SECONDS = 0.2

const _spread_directions = [
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 0, -1),
	Vector3(0, 0, 1),
	Vector3(0, -1, 0)
]

onready var _terrain : VoxelTerrain = get_node("../VoxelTerrain")
onready var _terrain_tool := _terrain.get_voxel_tool()
onready var _blocks : Blocks = get_node("../Blocks")

# TODO An efficient Queue data structure would be NICE
var _update_queue := []
var _process_queue := []
var _process_index := 0
var _scheduled_positions := {}
var _water_id := -1
var _water_top := -1
var _water_full := -1
var _time_before_next_process := 0.0


func _ready():
	_terrain_tool.set_channel(VoxelBuffer.CHANNEL_TYPE)
	var water = _blocks.get_block_by_name("water").base_info
	_water_id = water.id
	_water_full = water.voxels[0]
	_water_top = water.voxels[1]


func schedule(pos: Vector3):
	if _scheduled_positions.has(pos):
		return
	_scheduled_positions[pos] = true
	_update_queue.append(pos)


func _process(delta: float):
	_time_before_next_process -= delta
	if _time_before_next_process <= 0.0:
		_time_before_next_process += INTERVAL_SECONDS
		_do_process_queue()


func _do_process_queue():
	var update_count = 0
	
	if _process_index >= len(_process_queue):
		_process_queue.clear()
		_process_index = 0
		_swap_queues()

	while update_count < MAX_UPDATES_PER_FRAME:
		if _process_index >= len(_process_queue):
			_process_queue.clear()
			_process_index = 0
			#if len(_update_queue) == 0:
			#	# No more work
			#	break
			break
			_swap_queues()

		var pos = _process_queue[_process_index]
		_process_cell(pos)
		_scheduled_positions.erase(pos)
		
		_process_index += 1
		update_count += 1


func _swap_queues():
	var tmp := _update_queue
	_update_queue = _process_queue
	_process_queue = tmp


func _process_cell(pos: Vector3):
	var v := _terrain_tool.get_voxel(pos)
	var rm := _blocks.get_raw_mapping(v)
	
	if rm.block_id != _water_id:
		# Water got removed in the meantime
		return

	if v == _water_full:
		# Just to make sure the variant is correct
		_fill_with_water(pos)
	
	for di in len(_spread_directions):
		var npos = pos + _spread_directions[di]
		var nv = _terrain_tool.get_voxel(npos)
		if nv == Blocks.AIR_ID:
			_fill_with_water(npos)
			schedule(npos)


func _fill_with_water(pos: Vector3):
	var above := pos + Vector3(0, 1, 0)
	var below := pos - Vector3(0, 1, 0)
	var above_v := _terrain_tool.get_voxel(above)
	var below_v := _terrain_tool.get_voxel(below)
	var above_rm := _blocks.get_raw_mapping(above_v)
	# Make sure the top has the surface model
	if above_rm.block_id == _water_id:
		_terrain_tool.set_voxel(pos, _water_full)
	else:
		_terrain_tool.set_voxel(pos, _water_top)
	if below_v == _water_top:
		_terrain_tool.set_voxel(below, _water_full)
