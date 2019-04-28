extends Node


var _sphere_position = Vector3(8, 8, 8)
var _sphere_radius = 3.5
var _geometric_error = 0.01
var _mesh_instance = null
var _debug_mesh_instance = null
var _sphere_mesh_instance = null
var _model_rotation = 0.0
var _voxels = VoxelBuffer.new()
var _mesher = VoxelMesherDMC.new()
var _need_generate = false
var _iso_scale = 1.0

func _ready():
	
	_mesher.set_octree_mode(VoxelMesherDMC.OCTREE_NONE)

	_voxels.create(20, 20, 20)
	
	_mesh_instance = MeshInstance.new()
	_mesh_instance.material_override = SpatialMaterial.new()
	add_child(_mesh_instance)

	var mat = SpatialMaterial.new()
	mat.flags_unshaded = true
	mat.vertex_color_use_as_albedo = true
	_debug_mesh_instance = MeshInstance.new()
	_debug_mesh_instance.material_override = mat
	add_child(_debug_mesh_instance)

	_sphere_mesh_instance = create_sphere(_sphere_position, _sphere_radius)

	generate()


static func make_plane(pos, dir):
	return Plane(dir, dir.dot(pos))


func generate_with_stats():

	var stats_average = _mesher.get_stats()
	for k in stats_average:
		stats_average[k] = 0.0

	var iterations = 1
	for i in iterations:
		generate()
		var stats = _mesher.get_stats()
		for k in stats:
			stats_average[k] += stats[k]

	for k in stats_average:
		stats_average[k] = stats_average[k] / float(iterations)

	print("---")
	print("Sphere at ", _sphere_position, ", radius ", _sphere_radius)
	print("Geometric error: ", _geometric_error, ", iso_scale=", _iso_scale)
	print(stats_average)

	#------------------------------------------------------
	#_sphere_position = Vector3(8, 8, 8)
	#_sphere_radius = 3.5
	#_geometric_error = 0.01

	# On 3c366b1f098f7aa62b0c0bf61f97ef5e38531caa
	# {commit_time:663.96, dualgrid_derivation_time:4422, meshing_time:14576.8, octree_build_time:61293.9}

	# On 0e569df945f0277869d90b5df189df2a39d11ee0
	# {commit_time:588.13, dualgrid_derivation_time:2155.79, meshing_time:14476.36, octree_build_time:5830.69}


func generate():
	_voxels.fill_iso(1.0, VoxelBuffer.CHANNEL_ISOLEVEL)
	
	var vt = VoxelIsoSurfaceTool.new()
	vt.set_iso_scale(_iso_scale)
	vt.set_offset(Vector3(1, 1, 1)) # For padding
	vt.set_buffer(_voxels)
	vt.do_cube(Transform(Basis(Vector3(1, 0, 0), _model_rotation), _sphere_position), Vector3(_sphere_radius, _sphere_radius, _sphere_radius))
	#vt.do_sphere(_sphere_position, _sphere_radius)
	#vt.do_sphere(_sphere_position + Vector3(5,2,3), _sphere_radius / 1.5)
	#vt.do_plane(make_plane(_sphere_position, Vector3(0,1,0)))
	
	_mesher.set_mesh_mode(VoxelMesherDMC.MESH_NORMAL)
	_mesher.set_geometric_error(_geometric_error)
	var mesh = _mesher.build_mesh(_voxels)
	_mesh_instance.mesh = mesh
	_mesh_instance.material_override = load("res://dmc_terrain/dmc_terrain_material.tres")

	if false:
		_mesher.set_mesh_mode(VoxelMesherDMC.MODE_DEBUG_DUAL_GRID)
		mesh = _mesher.build_mesh(_voxels)
		_debug_mesh_instance.mesh = mesh

	_sphere_mesh_instance.translation = _sphere_position


func _process(delta):
	if _need_generate:
		generate_with_stats()
		_need_generate = false


func _input(event):
	if event is InputEventKey:
		if event.pressed:

			# Doesn't work, because reasons
			#if event.scancode == KEY_TAB:
			#	if get_viewport().debug_draw == Viewport.DEBUG_DRAW_DISABLED:
			#		print("Switched to wireframe render")
			#		get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
			#	else:
			#		print("Switched to normal render")
			#		get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED

			if event.scancode == KEY_RIGHT:
				_sphere_position.x += 0.1
				_need_generate = true

			elif event.scancode == KEY_LEFT:
				_sphere_position.x -= 0.1
				_need_generate = true

			elif event.scancode == KEY_UP:
				_sphere_position.z += 0.1
				_need_generate = true

			elif event.scancode == KEY_DOWN:
				_sphere_position.z -= 0.1
				_need_generate = true

			elif event.scancode == KEY_PAGEUP:
				_sphere_position.y += 0.1
				_need_generate = true

			elif event.scancode == KEY_PAGEDOWN:
				_sphere_position.y -= 0.1
				_need_generate = true

			elif event.scancode == KEY_KP_ADD:
				_sphere_radius += 0.1
				_sphere_mesh_instance.mesh.radius = _sphere_radius
				_sphere_mesh_instance.mesh.height = 2.0 * _sphere_radius
				_need_generate = true

			elif event.scancode == KEY_KP_SUBTRACT:
				_sphere_radius -= 0.1
				if _sphere_radius < 0.1:
					_sphere_radius = 0.1
				_sphere_mesh_instance.mesh.radius = _sphere_radius
				_sphere_mesh_instance.mesh.height = 2.0 * _sphere_radius
				_need_generate = true

			elif event.scancode == KEY_KP_8:
				_geometric_error += 0.025
				_need_generate = true

			elif event.scancode == KEY_KP_2:
				_geometric_error -= 0.025
				if _geometric_error < 0.0:
					_geometric_error = 0.0
				_need_generate = true

			elif event.scancode == KEY_KP_4:
				_model_rotation -= PI / 32.0
				_need_generate = true

			elif event.scancode == KEY_KP_6:
				_model_rotation += PI / 32.0
				_need_generate = true

			elif event.scancode == KEY_KP_7:
				_iso_scale -= 0.1
				if _iso_scale < 0.1:
					_iso_scale = 0.1
				_need_generate = true

			elif event.scancode == KEY_KP_9:
				_iso_scale += 0.1
				_need_generate = true

			elif event.scancode == KEY_P:
				print_buffer_to_images(_voxels, VoxelBuffer.CHANNEL_ISOLEVEL, "isolevel", 10)

			elif event.scancode == KEY_R:
				_need_generate = true


func create_sphere(pos, r):
	var mat = SpatialMaterial.new()
	mat.flags_transparent = true
	mat.albedo_color = Color(0,0,1,0.3)
	var mesh = SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	var mi = MeshInstance.new()
	mi.translation = pos
	mi.mesh = mesh
	mi.material_override = mat
	add_child(mi)
	return mi


static func print_buffer_to_images(voxels, channel, fname, upscale):
	
	for y in voxels.get_size_y():
		
		var im = Image.new()
		im.create(voxels.get_size_x(), voxels.get_size_z(), false, Image.FORMAT_RGB8)

		im.lock()

		for z in voxels.get_size_z():
			for x in voxels.get_size_x():
				var r = 0.5 * voxels.get_voxel_iso(x, y, z, channel) + 0.5
				if r < 0.5:
					im.set_pixel(x, z, Color(r, r, r*0.5 + 0.5))
				else:
					im.set_pixel(x, z, Color(r, r, r))

		im.unlock()

		if upscale > 1:
			im.resize(im.get_width() * upscale, im.get_height() * upscale, Image.INTERPOLATE_NEAREST)

		var fname_png = str(fname, "_", y, ".png")
		print("Saved ", fname_png)
		im.save_png(fname_png)


