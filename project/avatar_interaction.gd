extends Node

export(NodePath) var terrain_path = null
export(Material) var cursor_material = null

var _terrain = null
var _cursor = null
onready var _head = get_parent().get_node("Camera")


func _ready():
	_terrain = get_node(terrain_path)
	_cursor = _make_cursor()
	_terrain.add_child(_cursor)


func _fixed_process(delta):
	if _terrain == null:
		return
	
	var origin = _head.get_global_transform().origin
	var forward = -_head.get_transform().basis.z.normalized()
	
	var hit = _terrain.raycast(origin, forward, 10)
	var label = get_parent().get_node("debug_label")
	if hit != null:
		label.text = str(hit.position)
		_cursor.show()
		_cursor.set_translation(hit.position + Vector3(1,1,1)*0.5)
	else:
		label.text = "---"
		_cursor.hide()


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

