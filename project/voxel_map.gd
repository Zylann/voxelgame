
# Infinite terrain of voxels.
# Voxels are divided in blocks in all directions (like octants in Gridmap).
# It is a lot faster than Gridmap because geometry is merged in one mesh per block.
# Voxels are usually cubes, but they can of any shape (see voxel_type.gd).
# One thread is used to generate and bake geometry.

# TODO Immerge blocks that are too far away (they currently flood the memory at some point)
# TODO Voxel edition
# TODO Physics
# TODO Generate structures (trees, caves, old buildings... everything that is not made of a single voxel)
# TODO Move data crunching to a C++ module for faster generation and mesh baking
# TODO Ambient occlusion with vertex colors
# TODO Import .obj to voxel types
# TODO Move to a 2D Chunk-based generation system? More convenient for terrains (but keep Blocks for graphics)

extends Node

const BLOCK_SIZE = 16
const SORT_TIME = 1
#const TILE_SIZE = 16

export(Material) var solid_material = null
export(Material) var transparent_material = null
var view_radius = 4
var min_y = -4
var max_y = 4

var _blocks = {}
var _generating_blocks = {}
#var _chunks = {}

var _pending_blocks = []
var _thread = Thread.new()
var _time_before_sort = SORT_TIME
var _camera = null
var _voxel_types = []
var _priority_positions = []
var _outer_positions = []
var _precalc_neighboring = []

var _noise = OsnNoise.new()
var _mesh_builder = VoxelMeshBuilder.new()
var _library = VoxelLibrary.new()


class Block:
	var voxel_map = null
	var voxels = VoxelBuffer.new()
	var pos = Vector3(0,0,0)
	var mesh = null
	var node = null
	var gen_time = 0
	var has_generated = false
	var has_structures = false
	var need_update = false
	
	func _init():
		voxels.create(BLOCK_SIZE+2,BLOCK_SIZE+2,BLOCK_SIZE+2)
	
	func is_generated():
		return has_generated and has_structures
	
	func is_surrounded():
		var blocks = voxel_map._blocks
		var ngb = voxel_map._precalc_neighboring
		for v in ngb:
			if not blocks.has(pos + v):
				return false
		return false
		
	func get_ground_y(x,z):
		var types = voxel_map._voxel_types
		for y in range(BLOCK_SIZE-1, 0, -1):
			if not types[voxels[z][y][x]].is_transparent:
				return y
		return 0
		
	func local_to_map(vpos):
		return vpos + pos * BLOCK_SIZE


class BlockRequest:
	const TYPE_GENERATE = 0
	const TYPE_UPDATE = 0
	
	var type = 0
	var block_pos = Vector3(0,0,0)
	
	func _init(pos, type=TYPE_GENERATE):
		self.block_pos = pos
		self.type = type


#class Chunk:
#	var heightmap = []
#	
#	func _init():
#		heightmap.resize(BLOCK_SIZE+2)
#		for y in range(0, heightmap.size()):
#			var line = []
#			line.resize(BLOCK_SIZE+2)
#			heightmap[y] = line
#			for x in range(0, line.size()):
#				line[x] = 0


func _ready():
	_noise.set_seed(131183)
	
	_library.set_atlas_size(4)
	
	_camera = get_parent().get_node("Camera")
	
	_load_voxel_types()
	_precalculate_priority_positions()
	_precalculate_neighboring()
	_update_pending_blocks()
	
	set_process(true)


func _precalculate_neighboring():
	for z in range(-1, 2):
		for y in range(-1, 2):
			for x in range(-1, 2):
				if x != 0 and y != 0 and z != 0:
					_precalc_neighboring.append(Vector3(x,y,z))


func _load_voxel_types():
	_library.create_voxel(0, "air").set_transparent()
	_library.create_voxel(1, "grass_dirt").set_cube_geometry().set_cube_uv_tbs_sides(Vector2(0,0), Vector2(0,1), Vector2(1,0))
	_library.create_voxel(2, "dirt").set_cube_geometry().set_cube_uv_all_sides(Vector2(1,0))
	_library.create_voxel(3, "log").set_cube_geometry().set_cube_uv_tbs_sides(Vector2(3,0), Vector2(3,0), Vector2(2,0))
	_library.create_voxel(4, "water").set_transparent().set_cube_geometry(15.0/16.0).set_cube_uv_all_sides(Vector2(2,1)).set_material_id(1)
	
	_mesh_builder.set_library(_library)
	_mesh_builder.set_material(solid_material, 0)
	_mesh_builder.set_material(transparent_material, 1)


func _precalculate_priority_positions():
	_priority_positions.clear()
	for z in range(-view_radius, view_radius):
		for x in range(-view_radius, view_radius):
			for y in range(min_y, max_y):
				_priority_positions.append(Vector3(x,y,z))
	_priority_positions.sort_custom(self, "_compare_priority_positions")


func _compare_priority_positions(a, b):
	return a.length_squared() > b.length_squared()


func set_voxel(pos, id):
	# This function only works if the block exists and is surrounded
	
	var bpos = Vector3(floor(pos.x/BLOCK_SIZE), floor(pos.y/BLOCK_SIZE), floor(pos.z/BLOCK_SIZE))
	var block = _blocks[bpos]
	var rx = pos.x%BLOCK_SIZE
	var ry = pos.y%BLOCK_SIZE
	var rz = pos.z%BLOCK_SIZE
	block.voxels[rz+1][ry+1][rx+1] = id
	block.need_update = true
	
	# TODO The following is not needed if the meshing process could just take copies with neighboring,
	# So we don't need to keep boundaries information for all the lifetime of blocks
	
	if rx == 0:
		var nblock = _blocks[bpos-Vector3(1,0,0)]
		nblock.voxels[BLOCK_SIZE+1][ry+1][rx+1] = id
		nblock.need_update = true
	elif rx == BLOCK_SIZE-1:
		var nblock = _blocks[bpos+Vector3(1,0,0)]
		nblock.voxels[0][ry+1][rx+1] = id
		nblock.need_update = true
	
	if ry == 0:
		var nblock = _blocks[bpos-Vector3(0,1,0)]
		nblock.voxels[rx+1][BLOCK_SIZE+1][rx+1] = id
		nblock.need_update = true
	elif ry == BLOCK_SIZE-1:
		var nblock = _blocks[bpos+Vector3(0,1,0)]
		nblock.voxels[rx+1][0][rx+1] = id
		nblock.need_update = true

	if rz == 0:
		var nblock = _blocks[bpos-Vector3(0,0,1)]
		nblock.voxels[rz+1][ry+1][BLOCK_SIZE+1] = id
		nblock.need_update = true
	elif rz == BLOCK_SIZE-1:
		var nblock = _blocks[bpos+Vector3(0,0,1)]
		nblock.voxels[rx+1][ry+1][0] = id
		nblock.need_update = true


func _update_pending_blocks():
	# Using pre-sorted relative vectors is faster than sorting the list directly
	var camera_block_pos = _camera.get_translation() / BLOCK_SIZE
	camera_block_pos.x = floor(camera_block_pos.x)
	camera_block_pos.y = 0#floor(camera_block_pos.y)
	camera_block_pos.z = floor(camera_block_pos.z)
	_pending_blocks.clear()
	for rpos in _priority_positions:
		var pos = rpos + camera_block_pos
		if pos.y >= min_y and pos.y < max_y and not _generating_blocks.has(pos):
			if not _blocks.has(pos):
				_pending_blocks.append(pos)
#			else:
#				var block = _blocks[pos]
#				if block.need_update:
#					# TODO update mesh
#				elif not block.has_structures and block.is_surrounded():
#					# TODO generate structures


func _process(delta):
	
	# TODO Immerge blocks that are too far away

	if _time_before_sort > 0:
		_time_before_sort -= delta
		if _time_before_sort <= 0:
			_time_before_sort = SORT_TIME
			_update_pending_blocks()

	if _pending_blocks.size() != 0:
		if not _thread.is_active():
			
			# Closer blocks are loaded first
			var pos = _pending_blocks[_pending_blocks.size()-1]
			_pending_blocks.pop_back()
			_generating_blocks[pos] = true
			var arg = BlockRequest.new(pos, BlockRequest.TYPE_GENERATE)
			#_thread.start(self, "generate_block_thread", arg)
			#print("generate " + str(pos))
			spawn_block(generate_block(arg.block_pos))
			
			# Visible blocks are loaded first
#			var hbs = Vector3(0.5, 0.5, 0.5) * BLOCK_SIZE
#			for i in range(_pending_blocks.size()-1, 0, -1):
#				var pos = _pending_blocks[i]
#				var wpos = pos*BLOCK_SIZE + hbs
#				if not _camera.is_position_behind(wpos):
#					_pending_blocks[i] = _pending_blocks[_pending_blocks.size()-1]
#					_pending_blocks.pop_back()
#					_thread.start(self, "generate_block_thread", pos)
#					break


func generate_block_thread(request):
	if request.type == BlockRequest.TYPE_GENERATE:
		var block = generate_block(request.block_pos)
		# Call the main thread to wait
		call_deferred("thread_finished")
		#_generating_blocks.erase(block.pos) # Enable only without thread!
		return block
	else:
		print("Unknown request type " + str(request.type))


func thread_finished():
	var block = _thread.wait_to_finish()
	_generating_blocks.erase(block.pos)
	spawn_block(block)


func generate_block(pos):
	var time_before = OS.get_ticks_msec()
	
	var block = Block.new()
	block.pos = pos
	
	#time_before = OS.get_ticks_msec()
	var empty = generate_3d(block.voxels, pos * BLOCK_SIZE)
	#print("Generate: " + str(OS.get_ticks_msec() - time_before) + "ms")

	var mesh = null
	if empty:
		block.voxels = null
	else:
		#time_before = OS.get_ticks_msec()
		mesh = _mesh_builder.build(block.voxels)
		#print("Bake: " + str(OS.get_ticks_msec() - time_before) + "ms")

	block.voxel_map = self
	block.mesh = mesh
	block.gen_time = OS.get_ticks_msec() - time_before
	
	return block


func spawn_block(block):
	if block.mesh != null:
		var mesh_instance = preload("res://block.tscn").instance()
		mesh_instance.set_translation(block.pos * BLOCK_SIZE)
		mesh_instance.spawn()
		mesh_instance.set_mesh(block.mesh)
		mesh_instance.voxel_map = self
		add_child(mesh_instance)
		block.node = mesh_instance
	_blocks[block.pos] = block
	#print("Gen time: " + str(block.gen_time) + " (empty=" + str(block.mesh == null) + ")")


func generate_test(cubes, offset):
	cubes.set_voxel(1, 1,1,1)
	
	cubes.set_voxel(1, 3,1,1)
	cubes.set_voxel(1, 3,1,2)
	
	cubes.set_voxel(1, 5,1,1)
	cubes.set_voxel(1, 5,1,2)
	cubes.set_voxel(1, 5,2,1)

	cubes.set_voxel(1, 8,1,1)
	cubes.set_voxel(1, 8,2,1)
	cubes.set_voxel(1, 7,1,1)

	cubes.set_voxel(1, 11,1,1)
	cubes.set_voxel(1, 11,2,1)
	cubes.set_voxel(1, 10,1,1)
	cubes.set_voxel(1, 10,1,2)
	
	for x in range(4,7):
		for z in range(4,7):
			cubes.set_voxel(1, x, 2, z)
			cubes.set_voxel(1, x+5, 2, z)
	cubes.set_voxel(1, 5,3,5)
	cubes.set_voxel(1, 5,1,5)
	
	return false


func generate_3d(cubes, offset):
	var ox = offset.x
	var oy = offset.y
	var oz = offset.z
	var empty = true
	var bs = cubes.get_size_x()
	
	var noise1 = OsnFractalNoise.new()
	noise1.set_source_noise(_noise)
	noise1.set_period(100)
	noise1.set_octaves(4)
	
	var dirt = 1
	if oy < 0:
		dirt = 2

	for z in range(0, bs):
		for x in range(0, bs):
			for y in range(0, bs):
				var gy = y+oy
				var h = noise1.get_noise_3d(x+ox+2, gy, z+oz)
				if h < 1-gy*0.01 - 1:
					cubes.set_voxel(dirt, x, y, z)
					empty = false
				else:
					if gy < 0:
						cubes.set_voxel(4, x, y, z)
					else:
						cubes.set_voxel(0, x, y, z)
						empty = false
	
	return empty


func generate_heightmap(cubes, offset):
	var ox = offset.x
	var oy = offset.y
	var oz = offset.z
	var empty = true
	var ns1 = 0.01
	var ns2 = 0.05
	
	var dirt = 1
	if oy < 0:
		dirt = 2
	
	var bs = cubes.get_size_x()
	
	var noise1 = OsnFractalNoise.new()
	noise1.set_source_noise(_noise)
	noise1.set_period(128)
	noise1.set_octaves(4)
	
	for z in range(0, bs):
		for x in range(0, bs):
			
			var h = 16.0 * noise1.get_noise_2d(ox+x, oz+z) - oy
			
			if h >= 0:
				if h < bs:
					empty = false
					for y in range(0, h):
						cubes.set_voxel(dirt, x,y,z)
						#cubes[z][y][x] = dirt
					for y in range(h, bs):
						cubes.set_voxel(0, x,y,z)
						#cubes[z][y][x] = air
#					if oy == -BLOCK_SIZE:
#						cubes[z][bs-1][x] = 0
#					if oy >= 0 and randf() < 0.2:
#						cubes[z][h][x] = 2
#					if randf() < 0.01:
#						var th = h+1+randi()%8
#						if th > bs:
#							th = bs
#						for y in range(h, th):
#							cubes[z][y][x] = 3
				else:
					empty = false
					for y in range(0, bs):
						cubes.set_voxel(dirt, x,y,z)
			else:
				for y in range(0, bs):
					cubes.set_voxel(0, x,y,z)
	
	return empty





