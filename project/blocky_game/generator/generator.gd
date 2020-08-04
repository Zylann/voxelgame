#tool
extends VoxelGenerator

const Structure = preload("./structure.gd")
const TreeGenerator = preload("./tree_generator.gd")

# TODO Don't hardcode, get by name from library somehow
const AIR = 0
const DIRT = 1
const GRASS = 2
const WATER_FULL = 14
const WATER_TOP = 13
const LOG = 4
const LEAVES = 25
const TALL_GRASS = 8
#const STONE = 8

const _CHANNEL = VoxelBuffer.CHANNEL_TYPE

const _moore_dirs = [
	Vector3(-1, 0, -1),
	Vector3(0, 0, -1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(-1, 0, 1),
	Vector3(0, 0, 1),
	Vector3(1, 0, 1)
]


var _tree_structures := []

var _heightmap_min_y := -32
var _heightmap_max_y := 64
var _heightmap_range := 0
var _heightmap_noise := OpenSimplexNoise.new()
var _trees_min_y := 0
var _trees_max_y := 0


func _init():
	# TODO Even this must be based on a seed, but I'm lazy
	var tree_generator = TreeGenerator.new()
	tree_generator.log_type = LOG
	tree_generator.leaves_type = LEAVES
	for i in 16:
		var s = tree_generator.generate()
		_tree_structures.append(s)

	var tallest_tree_height = 0
	for structure in _tree_structures:
		var h = int(structure.voxels.get_size().y)
		if tallest_tree_height < h:
			tallest_tree_height = h
	_trees_min_y = _heightmap_min_y
	_trees_max_y = _heightmap_max_y + tallest_tree_height

	_heightmap_noise.period = 128
	_heightmap_noise.octaves = 4


func get_used_channels_mask() -> int:
	return 1 << _CHANNEL


func generate_block(buffer: VoxelBuffer, origin_in_voxels: Vector3, lod: int):
	# Assuming input is cubic in our use case (it doesn't have to be!)
	var block_size := int(buffer.get_size().x)
	var oy := int(origin_in_voxels.y)
	# TODO This hardcodes a cubic block size of 16, find a non-ugly way...
	# Dividing is a false friend because of negative values
	var chunk_pos := Vector3(
		int(origin_in_voxels.x) >> 4,
		int(origin_in_voxels.y) >> 4,
		int(origin_in_voxels.z) >> 4)

	_heightmap_range = _heightmap_max_y - _heightmap_min_y

	# Ground

	if origin_in_voxels.y > _heightmap_max_y:
		buffer.fill(AIR, _CHANNEL)

	elif origin_in_voxels.y + block_size < _heightmap_min_y:
		buffer.fill(DIRT, _CHANNEL)

	else:
		var rng := RandomNumberGenerator.new()
		rng.seed = get_chunk_seed_2d(chunk_pos)
		
		var gx : int
		var gz := int(origin_in_voxels.z)

		for z in block_size:
			gx = int(origin_in_voxels.x)

			for x in block_size:
				var h := _get_height_at(gx, gz)
				var rh := h - oy

				if rh > block_size:
					buffer.fill_area(DIRT,
						Vector3(x, 0, z), Vector3(x + 1, block_size, z + 1), _CHANNEL)
				elif rh > 0:
					buffer.fill_area(DIRT,
						Vector3(x, 0, z), Vector3(x + 1, rh, z + 1), _CHANNEL)
					if h > 0:
						buffer.set_voxel(GRASS, x, rh - 1, z, _CHANNEL)
						if rh < block_size and rng.randf() < 0.2:
							buffer.set_voxel(TALL_GRASS, x, rh, z, _CHANNEL)
							
					# TODO Tall grass

				gx += 1

			gz += 1

	# Trees

	if origin_in_voxels.y <= _trees_max_y and origin_in_voxels.y + block_size >= _trees_min_y:
		var voxel_tool := buffer.get_voxel_tool()
		var structure_instances := []
			
		get_tree_instances_in_chunk(chunk_pos, origin_in_voxels, block_size, structure_instances)
	
		# Relative to current block
		var block_aabb := AABB(Vector3(), buffer.get_size() + Vector3(1, 1, 1))

		for dir in _moore_dirs:
			var ncpos : Vector3 = (chunk_pos + dir).round()
			get_tree_instances_in_chunk(ncpos, origin_in_voxels, block_size, structure_instances)

		for structure_instance in structure_instances:
			var pos : Vector3 = structure_instance[0]
			var structure : Structure = structure_instance[1]
			var lower_corner_pos := pos - structure.offset
			var aabb := AABB(lower_corner_pos, structure.voxels.get_size() + Vector3(1, 1, 1))

			if aabb.intersects(block_aabb):
				voxel_tool.paste(lower_corner_pos, structure.voxels, AIR)


func get_tree_instances_in_chunk(
	cpos: Vector3, offset: Vector3, chunk_size: int, tree_instances: Array):
		
	var rng := RandomNumberGenerator.new()
	rng.seed = get_chunk_seed_2d(cpos)

	for i in 4:
		var pos := Vector3(rng.randi() % chunk_size, 0, rng.randi() % chunk_size)
		pos += cpos * chunk_size
		pos.y = _get_height_at(pos.x, pos.z)
		
		if pos.y > 0:
			pos -= offset
			var si := rng.randi() % len(_tree_structures)
			var structure : Structure = _tree_structures[si]
			tree_instances.append([pos.round(), structure])


#static func get_chunk_seed(cpos: Vector3) -> int:
#	return cpos.x ^ (13 * int(cpos.y)) ^ (31 * int(cpos.z))


static func get_chunk_seed_2d(cpos: Vector3) -> int:
	return int(cpos.x) ^ (31 * int(cpos.z))


func _get_height_at(x: int, z: int) -> int:
	return int(_heightmap_min_y + _heightmap_range \
		* (0.5 + 0.5 * _heightmap_noise.get_noise_2d(x, z)))
