extends Node

var radius = 0

func _ready():
	generate()


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_KP_ADD:
					radius += 8
					if radius > 255:
						radius = 255
					generate()
				KEY_KP_SUBTRACT:
					radius -= 8
					if radius < 0:
						radius = 0
					generate()


func generate():
	print("iso: ", radius)
	var voxels = VoxelBuffer.new()
	
	var size = 32
	voxels.create(size,size,size)
	var channel = VoxelBuffer.CHANNEL_ISOLEVEL
	
	voxels.fill(255, channel)
	
	if false:
		voxels.set_voxel(0, 4,4,4, channel)
		var v = 0
		voxels.set_voxel(120, 5,4,4, channel)
		voxels.set_voxel(v, 4,5,4, channel)
		voxels.set_voxel(v, 4,4,5, channel)
		voxels.set_voxel(v, 3,4,4, channel)
		voxels.set_voxel(v, 4,3,4, channel)
		voxels.set_voxel(v, 4,4,3, channel)
	
	if false:
		var s = 3
		var e = 5
		for z in range(s, e):
			for x in range(s, e):
				for y in range(s, e):
					voxels.set_voxel(int(radius), x, y, z, channel)
	
	if false:
		var r = 15
		for z in range(0, voxels.get_size_z()):
			for x in range(0, voxels.get_size_x()):
				for y in range(0, voxels.get_size_y()):
					var d = Vector3(16,16,16).distance_to(Vector3(x,y,z))
					var v = 0
					if d < r:
						v = 255
					voxels.set_voxel(v, x, y, z, channel)

	if true:
		var fractal_noise = OpenSimplexNoise.new()
		fractal_noise.octaves = 3
		fractal_noise.period = 16
		fractal_noise.persistence = 0.5

		for z in range(0, voxels.get_size_z()):
			for x in range(0, voxels.get_size_x()):
				for y in range(0, voxels.get_size_y()):
					var v = fractal_noise.get_noise_3d(x,y,z)
					if true:
						voxels.set_voxel_f(v, x,y,z, channel)
					else:
						if v > 0:
							v = 0
						else:
							v = 255
						voxels.set_voxel(v, x, y, z, channel)
	
	var tvm = VoxelMesherTransvoxel.new()
	var mesh = tvm.build_mesh(voxels)
	
	if mesh == null:
		print("The mesh is empty")
	get_node("MeshInstance").set_mesh(mesh)

