extends Node

export(NodePath) var terrain_path = null
export(Material) var cursor_material = null

const COLLISION_LAYER_AVATAR = 2

var _terrain = null
var _cursor = null

onready var _head = get_parent().get_node("Camera")


func _ready():
	if terrain_path == null:
		_terrain = get_parent().get_node(get_parent().terrain)
		terrain_path = _terrain.get_path() # For correctness
	else:
		_terrain = get_node(terrain_path)
	_cursor = _make_cursor()
	_terrain.add_child(_cursor)


func get_pointed_voxel():
	var origin = _head.get_global_transform().origin
	var forward = -_head.get_transform().basis.z.normalized()
	var hit = _terrain.raycast(origin, forward, 10)
	return hit


func _physics_process(delta):
	if _terrain == null:
		return
	
	var hit = get_pointed_voxel()
	if hit != null:
		_cursor.show()
		_cursor.set_translation(hit.position + Vector3(1,1,1)*0.5)
		get_parent().get_node("debug_label").text = str(hit.position)
	else:
		_cursor.hide()
		get_parent().get_node("debug_label").text = "---"
	
	# These inputs have to be in _fixed_process because they rely on collision queries
	if hit != null:
		var has_cube = _terrain.get_storage().get_voxel_v(hit.position) != 0
		
		if Input.is_action_just_pressed("action1") and has_cube:
			var pos = hit.position
			_terrain.get_storage().set_voxel_v(0, pos)
			_terrain.make_voxel_dirty(pos)
		
		elif Input.is_action_just_pressed("action2"):
			var pos = hit.prev_position
			if has_cube == false:
				pos = hit.position
			if can_place_voxel_at(pos):
				_terrain.get_storage().set_voxel_v(1, pos)
				_terrain.make_voxel_dirty(pos)
				print("Place voxel at ", pos)
			else:
				print("Can't place here!")


func can_place_voxel_at(pos):
	var space_state = get_viewport().get_world().get_direct_space_state()
	var params = PhysicsShapeQueryParameters.new()
	params.collision_mask = COLLISION_LAYER_AVATAR
	params.transform = Transform(Basis(), pos + Vector3(1,1,1)*0.5)
	var shape = BoxShape.new()
	var ex = 0.5
	shape.extents = Vector3(ex, ex, ex)
	params.set_shape(shape)
	var hits = space_state.intersect_shape(params)
	return hits.size() == 0


func _make_cursor():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	_add_wireframe_cube(st, -Vector3(1,1,1)*0.5, 1, Color(0,0,0))
	var mesh = st.commit()
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = mesh
	if cursor_material != null:
		mesh_instance.material_override = cursor_material
	mesh_instance.set_scale(Vector3(1,1,1)*1.01)
	return mesh_instance


static func _add_wireframe_cube(st, pos, step, color):
	
	st.add_color(color)
	
	st.add_vertex(pos)
	st.add_vertex(pos + Vector3(step, 0, 0))
	
	st.add_vertex(pos + Vector3(step, 0, 0))
	st.add_vertex(pos + Vector3(step, 0, step))

	st.add_vertex(pos + Vector3(step, 0, step))
	st.add_vertex(pos + Vector3(0, 0, step))
	
	st.add_vertex(pos + Vector3(0, 0, step))
	st.add_vertex(pos)


	st.add_vertex(pos + Vector3(0, step, 0))
	st.add_vertex(pos + Vector3(step, step, 0))
	
	st.add_vertex(pos + Vector3(step, step, 0))
	st.add_vertex(pos + Vector3(step, step, step))

	st.add_vertex(pos + Vector3(step, step, step))
	st.add_vertex(pos + Vector3(0, step, step))
	
	st.add_vertex(pos + Vector3(0, step, step))
	st.add_vertex(pos + Vector3(0, step, 0))


	st.add_vertex(pos)
	st.add_vertex(pos + Vector3(0, step, 0))

	st.add_vertex(pos + Vector3(step, 0, 0))
	st.add_vertex(pos + Vector3(step, step, 0))

	st.add_vertex(pos + Vector3(step, 0, step))
	st.add_vertex(pos + Vector3(step, step, step))

	st.add_vertex(pos + Vector3(0, 0, step))
	st.add_vertex(pos + Vector3(0, step, step))

