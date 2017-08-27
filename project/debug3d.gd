extends MeshInstance


var _boxes = []
var _colors = []
var _mesh = null

# Who said "use ImmediateGeometry" node?

func draw_wire_box(box, color=Color(1,1,1,1)):
	_boxes.append(box)
	_colors.append(color)


func _fixed_process(delta):
	
	if _mesh == null:
		_mesh = ArrayMesh.new()
		mesh = _mesh
	
	if _mesh.get_surface_count() != 0:
		_mesh.surface_remove(0)
	
	var positions = PoolVector3Array()
	var colors = PoolColorArray()
	var indices = PoolIntArray()
	
	for i in range(0, _boxes.size()):
		var box = _boxes[i]
		var color = _colors[i]
		
		var vi = positions.size()
		
		var pos = box.position
		var end = box.end
		
		var x0 = pos.x
		var y0 = pos.y
		var z0 = pos.z
		
		var x1 = end.x
		var y1 = end.y
		var z1 = end.z
		
		positions.append_array([
			Vector3(x0, y0, z0),
			Vector3(x1, y0, z0),
			Vector3(x1, y0, z1),
			Vector3(x0, y0, z1),
			
			Vector3(x0, y1, z0),
			Vector3(x1, y1, z0),
			Vector3(x1, y1, z1),
			Vector3(x0, y1, z1)
		])
		
		colors.append_array([
			color,
			color,
			color,
			color,
			color,
			color,
			color,
			color
		])
		
		indices.append_array([
			indices.append(vi),
			indices.append(vi+1),
			indices.append(vi+1),
			indices.append(vi+2),
			indices.append(vi+2),
			indices.append(vi+3),
			indices.append(vi+3),
			indices.append(vi),
			
			indices.append(vi+4),
			indices.append(vi+5),
			indices.append(vi+5),
			indices.append(vi+6),
			indices.append(vi+6),
			indices.append(vi+7),
			indices.append(vi+7),
			indices.append(vi+4),
			
			indices.append(vi),
			indices.append(vi+4),
			indices.append(vi+1),
			indices.append(vi+5),
			indices.append(vi+2),
			indices.append(vi+6),
			indices.append(vi+3),
			indices.append(vi+7)
		])
	
	if positions.size() != 0:
		var arrays = []
		# TODO Use ArrayMesh.ARRAY_MAX
		arrays.resize(9)
		arrays[ArrayMesh.ARRAY_VERTEX] = positions
		arrays[ArrayMesh.ARRAY_COLOR] = colors
		arrays[ArrayMesh.ARRAY_INDEX] = indices
		
		_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	_boxes.clear()
	_colors.clear()

