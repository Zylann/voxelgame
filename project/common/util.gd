
static func create_wirecube_mesh(color = Color(1,1,1)) -> ArrayMesh:
	var positions = PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1)
	])
	var colors = PackedColorArray([
		color, color, color, color,
		color, color, color, color,
	])
	var indices = PackedInt32Array([
		0, 1,
		1, 2,
		2, 3,
		3, 0,

		4, 5,
		5, 6,
		6, 7,
		7, 4,

		0, 4,
		1, 5,
		2, 6,
		3, 7
	])
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh


static func calculate_normals(positions, indices) -> PackedVector3Array:
	var out_normals = PackedVector3Array()
	
	var tcounts = []
	tcounts.resize(positions.size())
	out_normals.resize(positions.size())
	
	for i in range(0, tcounts.size()):
		tcounts[i] = 0
	
	var tri_count = indices.size() / 3
	
	var i = 0
	while i < indices.size():
		
		var i0 = indices[i]
		var i1 = indices[i+1]
		var i2 = indices[i+2]
		i += 3
		
		# TODO does triangle area matter?
		# If it does then we don't need to normalize in triangle calculation since
		# it will account for its length
		var n = get_triangle_normal(positions[i0], positions[i1], positions[i2])
		
		out_normals[i0] += n
		out_normals[i1] += n
		out_normals[i2] += n
		
		tcounts[i0] += 1
		tcounts[i1] += 1
		tcounts[i2] += 1
	
	for j in range(out_normals.size()):
		out_normals[j] = (out_normals[j] / float(tcounts[j])).normalized()
	#print("DDD ", out_normals.size())
	return out_normals


static func get_triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var u = (a - b).normalized()
	var v = (a - c).normalized()
	return v.cross(u)


static func get_longest_axis(v: Vector3) -> int:
	var lx = abs(v.x)
	var ly = abs(v.y)
	var lz = abs(v.z)
	if lx > ly and lx > lz:
		return Vector3.AXIS_X
	if ly > lx and ly > lz:
		return Vector3.AXIS_Y
	return Vector3.AXIS_Z


static func get_direction_id4(dir: Vector2) -> int:
	return int(4.0 * (dir.rotated(PI / 4.0).angle() + PI) / TAU)


static func vec3_has_nan(v: Vector3) -> bool:
	return is_nan(v.x) or is_nan(v.y) or is_nan(v.z)


static func basis_has_nan(b: Basis) -> bool:
	return vec3_has_nan(b.x) or vec3_has_nan(b.y) or vec3_has_nan(b.z)


static func transform_has_nan(t: Transform3D) -> bool:
	return vec3_has_nan(t.origin) or basis_has_nan(t.basis)
