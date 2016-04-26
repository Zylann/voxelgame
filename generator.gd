
extends Node

const BLOCK_SIZE = 16

const SIDE_LEFT = 0
const SIDE_RIGHT = 1
const SIDE_BOTTOM = 2
const SIDE_TOP = 3
const SIDE_BACK = 4
const SIDE_FRONT = 5

const SORT_TIME = 1
const TILE_SIZE = 16

export(Material) var material = null
export(Material) var transparent_material = null
var min_y = -2
var max_y = 2
var view_radius = 8

var _side_normals = [
	Vector3(-1,0,0),
	Vector3(1,0,0),
	Vector3(0,-1,0),
	Vector3(0,1,0),
	Vector3(0,0,-1),
	Vector3(0,0,1)
]

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


class Block:
	var voxel_map = null
	var voxels = []
	var pos = Vector3(0,0,0)
	var mesh = null
	var node = null
	var gen_time = 0
	var has_generated = false
	var has_structures = false
	var need_update = false
	
	func _init():
		pass
		#voxels = create_voxel_grid(BLOCK_SIZE+2,BLOCK_SIZE+2,BLOCK_SIZE+2)
	
	static func create_voxel_grid(sx,sy,sz):
		var grid = []
		grid.resize(sz)
		for z in range(0, sz):
			var plane = []
			plane.resize(sy)
			grid[z] = plane
			for y in range(0, sy):
				var line = []
				#var line = IntArray()
				line.resize(sx)
				plane[y] = line
				for x in range(0, sx):
					line[x] = 0
		return grid
	
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


class VoxelType:
	const GEOM_EMPTY = 0
	const GEOM_CUBE = 1
	const GEOM_XQUAD = 2
	const GEOM_MODEL = 3
	const GEOM_LIQUID = 4
	
	var id = 0
	var name = "default"
	var cube_side_uv4 = []
	var is_transparent = false
	var geom_type = GEOM_CUBE
	
	# Mesh that will always be included in the voxel
	var model_vertices = []
	var model_uv = []
	# Parts of the mesh that will appear only if connected sides are transparent
	var model_side_vertices = []
	var model_side_uv = []
	var model_normals = []
	
	func _init(id, name):
		self.id = id
		self.name = name
		cube_side_uv4.resize(6)
		set_all_atlas_pos(Vector2(0,0))
	
	func set_side_atlas_pos(side, pos):
		var s = 1.0 / 4.0
		# Apply a tiny padding to avoid tiling artefacts
		var e = 0.001 
		cube_side_uv4[side] = [
			s * (pos + Vector2(e,e)),
			s * (pos + Vector2(1-e,e)),
			s * (pos + Vector2(e,1-e)),
			s * (pos + Vector2(1-e,1-e))
		]
		return self
	
	func set_all_atlas_pos(pos):
		for i in range(0, 6):
			set_side_atlas_pos(i, pos)
		return self
	
	func set_tbs_atlas_pos(top_pos, bottom_pos, sides_pos):
		set_side_atlas_pos(SIDE_LEFT, sides_pos)
		set_side_atlas_pos(SIDE_RIGHT, sides_pos)
		set_side_atlas_pos(SIDE_FRONT, sides_pos)
		set_side_atlas_pos(SIDE_BACK, sides_pos)
		set_side_atlas_pos(SIDE_TOP, top_pos)
		set_side_atlas_pos(SIDE_BOTTOM, bottom_pos)
		return self
	
	func set_geom(g):
		geom_type = g
		return self
		
	func set_transparent(trans):
		is_transparent = trans
		return self
		
	func compile():
		if geom_type == GEOM_CUBE:
			model_side_vertices = _make_cube_vertex_offsets()
			model_side_uv = _make_cube_side_uv6(cube_side_uv4)
			
		elif geom_type == GEOM_LIQUID:
			model_side_vertices = _make_cube_vertex_offsets(15.0 / 16.0)
			model_side_uv = _make_cube_side_uv6(cube_side_uv4)
			
		elif geom_type == GEOM_XQUAD:
			var uv = cube_side_uv4
			model_uv = [
				uv[0][2],
				uv[0][0],
				uv[0][1],
				uv[0][2],
				uv[0][1],
				uv[0][3],
				
				uv[0][3],
				uv[0][2],
				uv[0][1],
				uv[0][2],
				uv[0][0],
				uv[0][1]
			]
			model_vertices = [
				Vector3(0,0,0),
				Vector3(0,1,0),
				Vector3(1,1,1),
				Vector3(0,0,0),
				Vector3(1,1,1),
				Vector3(1,0,1),
				
				Vector3(1,0,0),
				Vector3(0,0,1),
				Vector3(1,1,0),
				Vector3(0,0,1),
				Vector3(0,1,1),
				Vector3(1,1,0)
			]
			model_normals = [
				Vector3(-0.7, 0.0, 0.7),
				Vector3(-0.7, 0.0, 0.7),
				Vector3(-0.7, 0.0, 0.7),
				Vector3(-0.7, 0.0, 0.7),
				Vector3(-0.7, 0.0, 0.7),
				Vector3(-0.7, 0.0, 0.7),
				
				Vector3(0.7, 0.0, 0.7),
				Vector3(0.7, 0.0, 0.7),
				Vector3(0.7, 0.0, 0.7),
				Vector3(0.7, 0.0, 0.7),
				Vector3(0.7, 0.0, 0.7),
				Vector3(0.7, 0.0, 0.7)
			]
		
		else:
			print("Unknown voxel geometry type")


	static func _make_cube_vertex_offsets(sy=1):
		var a = [
			[
				# LEFT
				Vector3(0,0,0),
				Vector3(0,sy,0),
				Vector3(0,sy,1),
				Vector3(0,0,0),
				Vector3(0,sy,1),
				Vector3(0,0,1),
			],
			[
				# RIGHT
				Vector3(1,0,0),
				Vector3(1,sy,1),
				Vector3(1,sy,0),
				Vector3(1,0,0),
				Vector3(1,0,1),
				Vector3(1,sy,1)
			],
			[
				# BOTTOM
				Vector3(0,0,0),
				Vector3(1,0,1),
				Vector3(1,0,0),
				Vector3(0,0,0),
				Vector3(0,0,1),
				Vector3(1,0,1)
			],
			[
				# TOP
				Vector3(0,sy,0),
				Vector3(1,sy,0),
				Vector3(1,sy,1),
				Vector3(0,sy,0),
				Vector3(1,sy,1),
				Vector3(0,sy,1)
			],
			[
				# BACK
				Vector3(0,0,0),
				Vector3(1,0,0),
				Vector3(1,sy,0),
				Vector3(0,0,0),
				Vector3(1,sy,0),
				Vector3(0,sy,0),
			],
			[
				# FRONT
				Vector3(1,0,1),
				Vector3(0,0,1),
				Vector3(1,sy,1),
				Vector3(0,0,1),
				Vector3(0,sy,1),
				Vector3(1,sy,1)
			]
		]
		return a
		
	static func _make_cube_side_uv6(sides_uv4):
		var uvs = sides_uv4
		var uv6 = [
			[
				uvs[SIDE_LEFT][2],
				uvs[SIDE_LEFT][0],
				uvs[SIDE_LEFT][1],
				uvs[SIDE_LEFT][2],
				uvs[SIDE_LEFT][1],
				uvs[SIDE_LEFT][3]
			],
			[	
				uvs[SIDE_RIGHT][2],
				uvs[SIDE_RIGHT][1],
				uvs[SIDE_RIGHT][0],
				uvs[SIDE_RIGHT][2],
				uvs[SIDE_RIGHT][3],
				uvs[SIDE_RIGHT][1]
			],
			[
				uvs[SIDE_BOTTOM][0],
				uvs[SIDE_BOTTOM][3],
				uvs[SIDE_BOTTOM][1],
				uvs[SIDE_BOTTOM][0],
				uvs[SIDE_BOTTOM][2],
				uvs[SIDE_BOTTOM][3]
			],
			[
				uvs[SIDE_TOP][0],
				uvs[SIDE_TOP][1],
				uvs[SIDE_TOP][3],
				uvs[SIDE_TOP][0],
				uvs[SIDE_TOP][3],
				uvs[SIDE_TOP][2]
			],
			[
				uvs[SIDE_BACK][2],
				uvs[SIDE_BACK][3],
				uvs[SIDE_BACK][1],
				uvs[SIDE_BACK][2],
				uvs[SIDE_BACK][1],
				uvs[SIDE_BACK][0]
			],
			[
				uvs[SIDE_FRONT][3],
				uvs[SIDE_FRONT][2],
				uvs[SIDE_FRONT][1],
				uvs[SIDE_FRONT][2],
				uvs[SIDE_FRONT][0],
				uvs[SIDE_FRONT][1]
			],
		]
		return uv6


func _ready():
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


func add_voxel_type(id, name):
	var vt = VoxelType.new(id, name)
	if id >= _voxel_types.size():
		_voxel_types.resize(id+1)
	_voxel_types[id] = vt
	return vt


func _load_voxel_types():
	add_voxel_type(0, "air") \
		.set_geom(VoxelType.GEOM_EMPTY) \
		.set_transparent(true)
	
	add_voxel_type(1, "grassy_dirt") \
		.set_tbs_atlas_pos(Vector2(0,0), Vector2(1,0), Vector2(0,1))
	
	add_voxel_type(2, "bush") \
		.set_all_atlas_pos(Vector2(1,1)) \
		.set_geom(VoxelType.GEOM_XQUAD) \
		.set_transparent(true)

	add_voxel_type(3, "log") \
		.set_tbs_atlas_pos(Vector2(3,0), Vector2(3,0), Vector2(2,0))
	
	add_voxel_type(4, "dirt") \
		.set_all_atlas_pos(Vector2(1,0))
		
	add_voxel_type(5, "water") \
		.set_all_atlas_pos(Vector2(2,1)) \
		.set_transparent(true) \
		.set_geom(VoxelType.GEOM_LIQUID)
		
	for vt in _voxel_types:
		vt.compile()


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
	
	# TODO The following is not needed if the meshing process could just take copies with neighboring
	
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
			_thread.start(self, "generate_block_thread", BlockRequest.new(pos, BlockRequest.TYPE_GENERATE))
			_generating_blocks[pos] = true
			
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
		return block
	else:
		print("Unknown request type " + str(request.type))


func thread_finished():
	var block = _thread.wait_to_finish()
	_generating_blocks.erase(block.pos)
	spawn_block(block)


func generate_block(pos):
	var time_before = OS.get_ticks_msec()
	
	#var time_before = OS.get_ticks_msec()
	var voxels = Block.create_voxel_grid(BLOCK_SIZE+2, BLOCK_SIZE+2, BLOCK_SIZE+2)
	#print("Create: " + str(OS.get_ticks_msec() - time_before) + "ms")
	
	#time_before = OS.get_ticks_msec()
	var empty = generate_random(voxels, pos * BLOCK_SIZE)
	#print("Generate: " + str(OS.get_ticks_msec() - time_before) + "ms")

	var mesh = null
	if empty:
		voxels = null
	else:
		#time_before = OS.get_ticks_msec()
		var st_solid = SurfaceTool.new()
		var st_transparent = SurfaceTool.new()
		
		st_solid.begin(Mesh.PRIMITIVE_TRIANGLES)
		st_transparent.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		st_solid.set_material(material)
		st_transparent.set_material(transparent_material)
		
		make_mesh(voxels, st_solid, st_transparent)
		#st.index()
		
		mesh = st_solid.commit()
		st_transparent.commit(mesh)
		
		#print("Bake: " + str(OS.get_ticks_msec() - time_before) + "ms")

	var block = Block.new()
	block.voxel_map = self
	block.voxels = voxels
	block.pos = pos
	block.mesh = mesh
	block.gen_time = OS.get_ticks_msec() - time_before
	
	return block


func spawn_block(block):
	if block.mesh != null:
		var mesh_instance = preload("res://block.tscn").instance()
		mesh_instance.set_mesh(block.mesh)
		mesh_instance.set_translation(block.pos * BLOCK_SIZE)
		mesh_instance.voxel_map = self
		add_child(mesh_instance)
		block.node = mesh_instance
		mesh_instance.spawn()
	_blocks[block.pos] = block
	print("Gen time: " + str(block.gen_time) + " (empty=" + str(block.mesh == null) + ")")


func generate_random(cubes, offset):
	var ox = offset.x
	var oy = offset.y
	var oz = offset.z
	var empty = true
	var ns1 = 0.01
	var ns2 = 0.05
	
	var dirt = 1
	if oy < 0:
		dirt = 4
		
	var air = 0
	if oy < 0:
		air = 5
	
	var bs = cubes.size()
	
	for z in range(0, bs):
		for x in range(0, bs):
			#var h = 8.0*(cos((ox+x)/8.0) + sin((oz+z)/8.0)) + 8 - oy
			var n1 = preload("Simplex.gd").simplex2(ns1*(ox+x), ns1*(oz+z))
			var n2 = preload("Simplex.gd").simplex2(ns2*(ox+x+100.0), ns2*(oz+z))
			var h = 16.0*n1 + 4.0*n2 + 8 - oy
			if h >= 0:
				if h < bs:
					empty = false
					for y in range(0, h):
						cubes[z][y][x] = dirt
					for y in range(h, bs):
						cubes[z][y][x] = air
					if oy == -BLOCK_SIZE:
						cubes[z][bs-1][x] = 0
					if oy >= 0 and randf() < 0.2:
						cubes[z][h][x] = 2
#					if randf() < 0.01:
#						var th = h+1+randi()%8
#						if th > bs:
#							th = bs
#						for y in range(h, th):
#							cubes[z][y][x] = 3
				else:
					empty = false
					for y in range(0, bs):
						cubes[z][y][x] = 1
			else:
				for y in range(0, bs):
					cubes[z][y][x] = air
	
	return empty
	

func _is_face_visible(vt, other_vt):
	return other_vt.id == 0 or (other_vt.is_transparent and other_vt != vt)


func make_mesh(cubes, st_solid, st_transparent):
	
	for z in range(1, cubes.size()-1):
		var plane = cubes[z]
		for y in range(1, plane.size()-1):
			var line = plane[y]
			for x in range(1, line.size()-1):
				var voxel_id = line[x]
				if voxel_id != 0:
					var voxel_type = _voxel_types[voxel_id]
					
					var st = st_solid
					if voxel_type.is_transparent:
						st = st_transparent
					
					var ppos = Vector3(x,y,z)
					var pos = ppos-Vector3(1,1,1)
					
					# Side faces
					if voxel_type.model_side_vertices.size() != 0:
						for side in range(0,6):
							var npos = ppos + _side_normals[side]
							if _is_face_visible(voxel_type, _voxel_types[cubes[npos.z][npos.y][npos.x]]):
								st.add_normal(_side_normals[side])
								var uvs = voxel_type.model_side_uv[side]
								var vertices = voxel_type.model_side_vertices[side]
								for vi in range(0,vertices.size()):
									st.add_uv(uvs[vi])
									st.add_vertex(pos + vertices[vi])
					
					if voxel_type.geom_type == VoxelType.GEOM_XQUAD:
						pos.x += rand_range(-0.15, 0.15)
						pos.z += rand_range(-0.15, 0.15)
					
					# Model faces
					if voxel_type.model_vertices.size() != 0:
						var vertices = voxel_type.model_vertices
						var uvs = voxel_type.model_uv
						var normals = voxel_type.model_normals
						for vi in range(0, vertices.size()):
							st.add_uv(uvs[vi])
							st.add_normal(normals[vi])
							st.add_vertex(pos + vertices[vi])
					
#					elif voxel_type.geom_type == VoxelType.GEOM_XQUAD:
#						var pos = Vector3(x,y,z)-Vector3(1,1,1)
#						pos.x += rand_range(-0.15, 0.15)
#						pos.z += rand_range(-0.15, 0.15)
#						var uvs = voxel_type.cube_side_uv4[0]
#
#						st.add_normal(Vector3(-0.7,0,0.7))
#						st.add_uv(uvs[2]); st.add_vertex(pos)
#						st.add_uv(uvs[0]); st.add_vertex(pos+Vector3(0,1,0))
#						st.add_uv(uvs[1]); st.add_vertex(pos+Vector3(1,1,1))
#						st.add_uv(uvs[2]); st.add_vertex(pos)
#						st.add_uv(uvs[1]); st.add_vertex(pos+Vector3(1,1,1))
#						st.add_uv(uvs[3]); st.add_vertex(pos+Vector3(1,0,1))
#						
#						st.add_normal(Vector3(0.7,0,0.7))
#						st.add_uv(uvs[3]); st.add_vertex(pos+Vector3(1,0,0))
#						st.add_uv(uvs[2]); st.add_vertex(pos+Vector3(0,0,1))
#						st.add_uv(uvs[1]); st.add_vertex(pos+Vector3(1,1,0))
#						st.add_uv(uvs[2]); st.add_vertex(pos+Vector3(0,0,1))
#						st.add_uv(uvs[0]); st.add_vertex(pos+Vector3(0,1,1))
#						st.add_uv(uvs[1]); st.add_vertex(pos+Vector3(1,1,0))




