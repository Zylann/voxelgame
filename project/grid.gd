
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

	mesh = st.commit()
	#set_mesh(mesh)

