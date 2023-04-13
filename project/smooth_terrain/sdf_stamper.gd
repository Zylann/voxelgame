extends Node


var _terrain : VoxelLodTerrain
var _voxel_tool : VoxelToolLodTerrain
var _active := false
var _mesh : Mesh
var _mesh_sdf := VoxelMeshSDF.new()
var _has_hit := false
var _hit_position := Vector3()
var _hit_normal := Vector3()
var _preview_mesh_instance : MeshInstance3D
const _mesh_scale := 10.0


func _ready():
	# Has to be done in `_ready` because `set_process` has no effect before that, it's overriden by
	# the automatic detection of the presence of `_process`,
	# which happens in the READY notification...
	set_active(false)


func set_terrain(terrain: VoxelLodTerrain):
	_terrain = terrain
	_voxel_tool = terrain.get_voxel_tool()


func set_active(active: bool):
	_active = active

	set_process(active)
	set_physics_process(active)

	_has_hit = false

	if _preview_mesh_instance != null:
		_preview_mesh_instance.visible = _active

	if _active and (not _mesh_sdf.is_baked()) and (not _mesh_sdf.is_baking()):
		# TODO This is not supposed to be a requirement.
		# Check source code of `VoxelMeshSDF` to see why `get_tree()` is necessary...
		assert(is_inside_tree())

		var mesh = load("res://smooth_terrain/suzanne.obj")
		#var mesh = load("res://smooth_terrain/icosphere.obj")
		#var mesh = load("res://smooth_terrain/cube.obj")
		_mesh_sdf.mesh = mesh
		_mesh_sdf.baked.connect(_on_mesh_sdf_baked)
		_mesh_sdf.bake_async(get_tree())
		_mesh = mesh
		print("Building mesh SDF...")


func _on_mesh_sdf_baked():
	# Debug
	# var images = _mesh_sdf.get_voxel_buffer().debug_print_sdf_y_slices(1.0)
	# for i in len(images):
	# 	var im = images[i]
	# 	var fpath = str("debug_data/sdf_slice_", i, ".png")
	# 	var err = im.save_png(fpath)
	# 	if err != OK:
	# 		push_error(str("Could not save image ", fpath, ", error ", err))

	print("Building mesh SDF done")


func _physics_process(delta):
	var space_state = get_viewport().get_world_3d().direct_space_state
	var camera = get_viewport().get_camera_3d()

	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = get_parent().global_transform.origin
	ray.to = ray.from - 100.0 * camera.global_transform.basis.z

	var hit = space_state.intersect_ray(ray)
	_has_hit = not hit.is_empty()

	if not hit.is_empty():
		_hit_position = hit.position
		_hit_normal = hit.normal


func _process(delta: float):
	if _has_hit:
		if _preview_mesh_instance == null:
			var mi := MeshInstance3D.new()
			mi.mesh = _mesh
			var mat := StandardMaterial3D.new()
			mi.material_override = mat
			add_child(mi)
			_preview_mesh_instance = mi

		var mat : StandardMaterial3D = _preview_mesh_instance.material_override
		if _mesh_sdf.is_baked():
			mat.albedo_color = Color(1, 1, 1, 0.5)
		else:
			mat.albedo_color = Color(1, 0, 0, 0.5)

		var mesh_scale_v := Vector3(_mesh_scale, _mesh_scale, _mesh_scale)
		var hit_basis := Basis().looking_at(_hit_normal, Vector3(0,1,0)).scaled(mesh_scale_v)
		hit_basis = hit_basis.rotated(hit_basis.x.normalized(), -PI / 2.0)
		var hit_transform := Transform3D(hit_basis, _hit_position + _hit_normal * _mesh_scale * 0.7)

		_preview_mesh_instance.transform = hit_transform
		_preview_mesh_instance.show()

	else:
		if _preview_mesh_instance != null:
			_preview_mesh_instance.hide()


func place():
	if not _mesh_sdf.is_baked():
		print("Mesh SDF not ready")
		return
	if not _has_hit:
		print("Not hit")
		return
	var place_transform := _preview_mesh_instance.transform
	_voxel_tool.stamp_sdf(_mesh_sdf, place_transform, 0.1, _mesh_scale * 0.1)


