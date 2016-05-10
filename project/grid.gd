
extends MeshInstance

var step = 16


func _ready():
	
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_LINES)
	
	st.add_color(Color(0,0,0))
	
	var r = 4
	var rv = 4 * step
	
	for i in range(-r, r):
		for j in range(-r, r):
			
			var x = i * step
			var y = j * step
			
			st.add_vertex(Vector3(x, -rv, y))
			st.add_vertex(Vector3(x, rv, y))
			
			st.add_vertex(Vector3(x, y, -rv))
			st.add_vertex(Vector3(x, y, rv))
			
			st.add_vertex(Vector3(-rv, x, y))
			st.add_vertex(Vector3(rv, x, y))

	var mesh = st.commit()
	set_mesh(mesh)



#func _add_wireframe_cube(st, pos):
#	
#	st.add_vertex(pos)
#	st.add_vertex(pos + Vector3(step, 0, 0))
#	
#	st.add_vertex(pos + Vector3(step, 0, 0))
#	st.add_vertex(pos + Vector3(step, 0, step))
#
#	st.add_vertex(pos + Vector3(step, 0, step))
#	st.add_vertex(pos + Vector3(0, 0, step))
#	
#	st.add_vertex(pos + Vector3(0, 0, step))
#	st.add_vertex(pos)
#
#
#	st.add_vertex(pos + Vector3(0, step, 0))
#	st.add_vertex(pos + Vector3(step, step, 0))
#	
#	st.add_vertex(pos + Vector3(step, step, 0))
#	st.add_vertex(pos + Vector3(step, step, step))
#
#	st.add_vertex(pos + Vector3(step, step, step))
#	st.add_vertex(pos + Vector3(0, step, step))
#	
#	st.add_vertex(pos + Vector3(0, step, step))
#	st.add_vertex(pos + Vector3(0, step, 0))
#
#
#	st.add_vertex(pos)
#	st.add_vertex(pos + Vector3(0, step, 0))
#
#	st.add_vertex(pos + Vector3(step, 0, 0))
#	st.add_vertex(pos + Vector3(step, step, 0))
#
#	st.add_vertex(pos + Vector3(step, 0, step))
#	st.add_vertex(pos + Vector3(step, step, step))
#
#	st.add_vertex(pos + Vector3(0, 0, step))
#	st.add_vertex(pos + Vector3(0, step, step))
