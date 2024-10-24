extends Node


const TreeGenerator = preload("./tree_generator.gd")
const VoxelLibraryResource = preload("../blocks/voxel_library.tres")

const _materials = [
	preload("../blocks/terrain_material.tres"),
	preload("../blocks/terrain_material_foliage.tres"),
	preload("../blocks/terrain_material_transparent.tres")
]


@onready var _mesh_instance : MeshInstance3D = $MeshInstance3D


func _ready():
	_generate()


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_SPACE:
				_generate()


func _generate():
	var tree_generator := TreeGenerator.new()
	tree_generator.log_type = VoxelLibraryResource.get_model_index_from_resource_name("log_y")
	tree_generator.leaves_type = VoxelLibraryResource.get_model_index_from_resource_name("dirt")
	
	var s = tree_generator.generate()

	var padded_voxels := VoxelBuffer.new()
	padded_voxels.create(
		s.voxels.get_size().x + 2, s.voxels.get_size().y + 2, s.voxels.get_size().z + 2)
	padded_voxels.copy_channel_from_area(
		s.voxels, Vector3(), s.voxels.get_size(), Vector3(1, 1, 1), VoxelBuffer.CHANNEL_TYPE)

	var mesher = VoxelMesherBlocky.new()
	mesher.set_library(VoxelLibraryResource)
	var mesh = mesher.build_mesh(padded_voxels, _materials)
	
	_mesh_instance.mesh = mesh
	
