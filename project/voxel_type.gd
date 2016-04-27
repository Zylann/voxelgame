
# TODO Move this to VoxelMap
# Still here, because accessing constants from another script don't work... (issue 4457)
const ATLAS_SIZE = 4

const SIDE_LEFT = 0
const SIDE_RIGHT = 1
const SIDE_BOTTOM = 2
const SIDE_TOP = 3
const SIDE_BACK = 4
const SIDE_FRONT = 5

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
	var s = 1.0 / float(ATLAS_SIZE)
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


