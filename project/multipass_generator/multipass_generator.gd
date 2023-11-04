extends VoxelGeneratorMultipassCB

const CHANNEL = VoxelBuffer.CHANNEL_TYPE

const AIR = 0
const STONE = 1
const LOG = 2
const LEAVES = 3

const SEED = 1337

var _noise : FastNoiseLite


func _init():
	_noise = FastNoiseLite.new()
	_noise.frequency = 1.0 / 128.0
	_noise.seed = SEED


func _generate_pass(voxel_tool: VoxelToolMultipassGenerator, pass_index: int):
	voxel_tool.channel = CHANNEL

	var min_pos := voxel_tool.get_main_area_min()
	var max_pos := voxel_tool.get_main_area_max()
#	print("pass ", pass_index, ", min_pos: ", min_pos, ", max_pos: ", max_pos)
		
	if pass_index == 0:
		for gz in range(min_pos.z, max_pos.z):
			for gx in range(min_pos.x, max_pos.x):
				var height := 20.0 * _noise.get_noise_2d(gx, gz)
				voxel_tool.value = STONE
				voxel_tool.do_box(Vector3i(gx, min_pos.y, gz), Vector3i(gx, height, gz))
		
		# This is just for testing do_path, also creating overhangs that show how tree generation
		# benefits from multipass. In practice it's quite slow without checking boundaries.
		generate_spiral(voxel_tool)
	
	elif pass_index == 1:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(Vector2i(min_pos.x, min_pos.z)) + SEED
		
		var tree_count := 3#rng.randi_range(0, 3)
		
		for tree_index in tree_count:
			try_plant_tree(voxel_tool, rng)


static func generate_spiral(voxel_tool: VoxelToolMultipassGenerator):
	var positions := PackedVector3Array()
	var radii := PackedFloat32Array()
	
	var point_count := 100
	var length := 100.0
	var begin_position := Vector3(-40.0, 20.0, 20.0)
	var radius := 15.0
	var twist := 25.0
	
	for i in point_count:
		var t := i / float(point_count)
		positions.append(begin_position + Vector3(
			t * length, # X
			radius * cos(t * twist), # Y
			radius * sin(t * twist) # Z
		))
		radii.append(lerpf(2.0, 4.0, 0.5 + 0.5 * sin(t * 100.0)))

	voxel_tool.do_path(positions, radii)


static func try_plant_tree(voxel_tool: VoxelToolMultipassGenerator, rng: RandomNumberGenerator):
	var min_pos := voxel_tool.get_main_area_min()
	var max_pos := voxel_tool.get_main_area_max()
	var chunk_size = max_pos - min_pos
	
	var tree_rpos := Vector3i(
		rng.randi_range(0, chunk_size.x), 0,
		rng.randi_range(0, chunk_size.z)
	)
#	print("Trying to plant a tree at ", tree_rpos)
	
	var tree_pos := min_pos + tree_rpos
	tree_pos.y = max_pos.y - 1
	
	var found_ground := false
	while tree_pos.y >= min_pos.y:
		var v := voxel_tool.get_voxel(tree_pos)
		# Note, we could also find tree blocks that were placed earlier!
		if v == STONE:
			found_ground = true
			break
		tree_pos.y -= 1
	
	if not found_ground:
#		print("Ground not found")
		return
	
	# Plant tree
	var trunk_height := rng.randi_range(8, 15)
	var leaves_min_y := 3 * trunk_height / 2
	var leaves_max_y := trunk_height + 2
	var leaves_min_radius := 2
	var leaves_max_radius := 5
	
	if tree_pos.y + leaves_max_y + leaves_max_radius >= max_pos.y:
		# Too high
#		print("Too high")
		return
	
	voxel_tool.value = LEAVES
	for i in 5:
		var center := tree_pos + Vector3i(0, rng.randi_range(leaves_min_y, leaves_max_y), 0)
		var radius := rng.randf_range(leaves_min_radius, leaves_max_radius)
		voxel_tool.do_sphere(center, radius)

	voxel_tool.value = LOG
	voxel_tool.do_box(tree_pos, tree_pos + Vector3i(0, trunk_height, 0))


func _generate_block_fallback(out_buffer: VoxelBuffer, origin_in_voxels: Vector3i):
	pass


func _get_used_channels_mask() -> int:
	return 1 << CHANNEL


