
var _wireframe_indices = []
var _blacklist = {}


func build(mesh):
	if mesh == null:
		return null
	var arrays = mesh.surface_get_arrays(0)
	var positions = arrays[Mesh.ARRAY_VERTEX]
	var indices = arrays[Mesh.ARRAY_INDEX]
	_wireframe_indices.clear()
	_blacklist.clear()
	var i = 0
	assert(len(indices) % 3 == 0)
	while i < len(indices):
		_try_add_edge(indices[i], indices[i + 1])
		_try_add_edge(indices[i + 1], indices[i + 2])
		_try_add_edge(indices[i + 2], indices[i])
		i += 3
	var wireframe_arrays = []
	wireframe_arrays.resize(Mesh.ARRAY_MAX)
	wireframe_arrays[Mesh.ARRAY_VERTEX] = positions
	wireframe_arrays[Mesh.ARRAY_INDEX] = PoolIntArray(_wireframe_indices)
	
	var colors = PoolColorArray()
	colors.resize(len(positions))
	wireframe_arrays[Mesh.ARRAY_COLOR] = colors

	var wireframe_mesh = ArrayMesh.new()
	wireframe_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, wireframe_arrays)
	return wireframe_mesh


func _try_add_edge(i0, i1):
	assert(i0 < 0xffff)
	assert(i1 < 0xffff)
	var e = i0 | (i1 << 16)
	if _blacklist.has(e):
		return
	_blacklist[e] = true
	_wireframe_indices.append(i0)
	_wireframe_indices.append(i1)

