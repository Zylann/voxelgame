extends Node

const Util = preload("res://common/util.gd")

@onready var _terrain : VoxelTerrain = $VoxelTerrain
@onready var _cursor_from : MeshInstance3D = $CursorFrom
@onready var _cursor_to : MeshInstance3D = $CursorTo

var _voxel_tool : VoxelTool
var _pathfinder : VoxelAStarGrid3D
var _pointed_pos := Vector3i()
var _pointed_prev_pos := Vector3i()
var _has_pointed_pos := false
var _src_pos := Vector3i(11, -12, 19)
var _dst_pos := Vector3i(29, -15, 21)
var _cursor : MeshInstance3D
var _path_multimesh_instance : MultiMeshInstance3D
var _debug_visited_cells_multimesh_instance : MultiMeshInstance3D
var _search_radius: int = 40
var _use_async: bool = false


func _ready() -> void:
	_pathfinder = VoxelAStarGrid3D.new()
	_pathfinder.set_terrain(_terrain)
	_pathfinder.async_search_completed.connect(_on_async_search_completed)

	_voxel_tool = _terrain.get_voxel_tool()
	
	_setup_cursor()

	_path_multimesh_instance = _setup_multimesh(Color(0.0, 0.0, 1.0), 1.0)
	_debug_visited_cells_multimesh_instance = _setup_multimesh(Color(1.0, 1.0, 0.0, 0.3), 0.99)


func _setup_cursor() -> void:
	_cursor = MeshInstance3D.new()
	_cursor.mesh = Util.create_wirecube_mesh()
	add_child(_cursor)


func _setup_multimesh(color: Color, box_size: float) -> MultiMeshInstance3D:
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = Vector3(box_size, box_size, box_size)

	var multimesh := MultiMesh.new()
	multimesh.mesh = cube_mesh
	multimesh.transform_format = MultiMesh.TRANSFORM_3D

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = multimesh
	add_child(mmi)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mmi.material_override = mat

	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	return mmi


func _input(event: InputEvent) -> void:
	var mouse_motion_event := event as InputEventMouseMotion
	if mouse_motion_event != null:
		var mouse_pos : Vector2 = mouse_motion_event.position
		var camera := get_viewport().get_camera_3d()
		var ray_origin := camera.project_ray_origin(mouse_pos)
		var ray_dir := camera.project_ray_normal(mouse_pos)
		var hit := _voxel_tool.raycast(ray_origin, ray_dir, 100.0)
		if hit != null:
			_pointed_pos = hit.position
			_pointed_prev_pos = hit.previous_position
			_has_pointed_pos = true
		else:
			_has_pointed_pos = false
		return
	
	var mouse_button_event := event as InputEventMouseButton
	if mouse_button_event != null:
		if mouse_button_event.pressed:
			match mouse_button_event.button_index:
				MOUSE_BUTTON_LEFT:
					_dst_pos = _pointed_prev_pos
					print("Destination position: ", _dst_pos)

				MOUSE_BUTTON_RIGHT:
					_src_pos = _pointed_prev_pos
					_update_pathfinder_region()
					print("Source position: ", _src_pos)
		return
	
	var key_event := event as InputEventKey
	if key_event != null:
		if key_event.pressed:
			match key_event.keycode:
				KEY_SPACE:
					if _pathfinder.is_running_async():
						return
					
					_update_pathfinder_region()
					
					if _use_async:
						_pathfinder.find_path_async(_src_pos, _dst_pos)
					
					else:
						var path := _pathfinder.find_path(_src_pos, _dst_pos)
						_handle_path(path)
		return


func _update_pathfinder_region() -> void:
	_pathfinder.set_region(AABB(_src_pos, Vector3()).grow(_search_radius))


func _on_async_search_completed(path: Array[Vector3i]):
	_handle_path(path)


func _handle_path(path: Array[Vector3i]) -> void:
	print("Path size: ", path.size())
	_update_multimesh(_path_multimesh_instance, path)

	var visited_positions := _pathfinder.debug_get_visited_positions()
	_update_multimesh(_debug_visited_cells_multimesh_instance, visited_positions)


func _update_multimesh(mmi: MultiMeshInstance3D, path: Array[Vector3i]) -> void:
	var multimesh := mmi.multimesh
	multimesh.instance_count = path.size()
	var i := 0
	for pos in path:
		multimesh.set_instance_transform(i, 
			Transform3D(Basis(), Vector3(pos) + Vector3(0.5, 0.5, 0.5)))
		i += 1


func _process(_unused_delta: float) -> void:
	_cursor.position = _pointed_prev_pos
	_cursor_from.position = Vector3(_src_pos) + Vector3(0.5, 0.5, 0.5)
	_cursor_to.position = Vector3(_dst_pos) + Vector3(0.5, 0.5, 0.5)
	
	DDD.draw_box_aabb(_pathfinder.get_region())
