
const Blocks = preload("../blocks/blocks.gd")
const Util = preload("res://common/util.gd")
const WaterUpdater = preload("./../water.gd")


static func place_single_block(terrain_tool: VoxelTool, pos: Vector3, look_dir: Vector3,
	block_id: int, block_types: Blocks, water_updater: WaterUpdater):
	
	var block := block_types.get_block(block_id)
	var voxel_id := 0

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
			block.place(terrain_tool, pos, look_dir)
		_:
			# Unknown value
			assert(false)
	
	if block.base_info.rotation_type != Blocks.ROTATION_TYPE_CUSTOM_BEHAVIOR:
		terrain_tool.value = voxel_id
		terrain_tool.do_point(pos)
	
	water_updater.schedule(pos)

