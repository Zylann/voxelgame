
extends MeshInstance

export var size = 4
export var step = 16


func _ready():
	
	var st = SurfaceTool.new()
	
	st.begin(Mesh.PRIMITIVE_LINES)
	
	st.add_color(Color(0,0,0))
	
	var wsize = step * size
	
	for i in range(0, size+1):
		for j in range(0, size+1):
			
			var x = i * step
			var y = j * step
			
			st.add_vertex(Vector3(x, 0, y))
			st.add_vertex(Vector3(x, wsize, y))
			
			st.add_vertex(Vector3(x, y, 0))
			st.add_vertex(Vector3(x, y, wsize))
			
			st.add_vertex(Vector3(0, x, y))
			st.add_vertex(Vector3(wsize, x, y))

	mesh = st.commit()
	#set_mesh(mesh)

