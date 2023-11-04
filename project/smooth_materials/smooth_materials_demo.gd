extends Node

const HUD = preload("./hud.gd")

@onready var _cursor : MeshInstance3D = $Cursor
@onready var _terrain : VoxelTerrain = $VoxelTerrain
@onready var _hud : HUD = $HUD

var _voxel_tool : VoxelTool
var _brush_radius := 2.5
var _cmd_paint := false


func _ready():
	_voxel_tool = _terrain.get_voxel_tool()
	_voxel_tool.texture_index = 1
	
	_cursor.scale = Vector3(_brush_radius, _brush_radius, _brush_radius)
	
	_hud.set_selected_material_index(_voxel_tool.texture_index)


func _physics_process(delta):
	var camera := get_viewport().get_camera_3d()
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_direction := camera.project_ray_normal(mouse_pos)
	
	var raycast := PhysicsRayQueryParameters3D.new()
	raycast.from = ray_origin
	raycast.to = ray_origin + ray_direction * 100.0
	var space_state := get_viewport().world_3d.direct_space_state
	var hit := space_state.intersect_ray(raycast)
	
	if hit.is_empty():
		_cursor.hide()
	else:
		_cursor.show()
		_cursor.position = hit.position
	
	if _cmd_paint:
		_voxel_tool.mode = VoxelTool.MODE_TEXTURE_PAINT
		_voxel_tool.channel = VoxelBuffer.CHANNEL_SDF
		_voxel_tool.do_sphere(_cursor.position, _brush_radius)
	
	# Read current materials near the pointed surface
	_voxel_tool.channel = VoxelBuffer.CHANNEL_INDICES
	var encoded_indices := _voxel_tool.get_voxel(_cursor.position)
	_voxel_tool.channel = VoxelBuffer.CHANNEL_WEIGHTS
	var encoded_weights := _voxel_tool.get_voxel(_cursor.position)
	
	var indices := VoxelTool.u16_indices_to_vec4i(encoded_indices)
	var weights := VoxelTool.u16_weights_to_color(encoded_weights)
	
	_hud.set_pointed_label(str("Pointed:\n",
		"[0] Texture ", indices.x, ": ", int(100.0 * weights.r), "%\n",
		"[1] Texture ", indices.y, ": ", int(100.0 * weights.g), "%\n",
		"[2] Texture ", indices.z, ": ", int(100.0 * weights.b), "%\n",
		"[3] Texture ", indices.w, ": ", int(100.0 * weights.a), "%"
		))


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			_cmd_paint = true
		else:
			_cmd_paint = false


func _on_hud_material_selected(index: int):
	_voxel_tool.texture_index = index

