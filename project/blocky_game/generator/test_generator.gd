extends Node


const Generator = preload("./generator.gd")
const Util = preload("res://common/util.gd")
const VoxelLibraryResource = preload("../blocks/voxel_library.tres")

const _materials = [
	preload("../blocks/terrain_material.tres"),
	preload("../blocks/terrain_material_transparent.tres"),
	preload("../blocks/terrain_material_foliage.tres")
]


@onready var _mesh_instance : MeshInstance3D = $MeshInstance3D

var _origin = Vector3()
var _generator = Generator.new()


func _ready():
	VoxelLibraryResource.bake()
	_generate()
	
	var wireframe = Util.create_wirecube_mesh()
	var wireframe_instance = MeshInstance3D.new()
	wireframe_instance.mesh = wireframe
	wireframe_instance.scale = Vector3(16, 16, 16)
	add_child(wireframe_instance)


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_SPACE:
					_generate()
				KEY_LEFT:
					_origin.x -= 16
					_generate()
				KEY_RIGHT:
					_origin.x += 16
					_generate()
				KEY_DOWN:
					_origin.z -= 16
					_generate()
				KEY_UP:
					_origin.z += 16
					_generate()
				KEY_PAGEUP:
					_origin.y += 16
					_generate()
				KEY_PAGEDOWN:
					_origin.y -= 16
					_generate()


func _generate():
	var voxels = VoxelBuffer.new()
	voxels.create(16, 16, 16)
	_generator.generate_block(voxels, _origin, 0)

	var padded_voxels = VoxelBuffer.new()
	padded_voxels.create(
		voxels.get_size().x + 2, 
		voxels.get_size().y + 2, 
		voxels.get_size().z + 2)
	padded_voxels.copy_channel_from_area(
		voxels, Vector3(), voxels.get_size(), Vector3(1, 1, 1), VoxelBuffer.CHANNEL_TYPE)

	var mesher = VoxelMesherBlocky.new()
	mesher.set_library(VoxelLibraryResource)
	var mesh = mesher.build_mesh(padded_voxels, _materials)
	
	_mesh_instance.mesh = mesh
