
extends VoxelTerrain

export(Material) var solid_material = null
export(Material) var transparent_material = null

var _library = VoxelLibrary.new()
var _generator = null


func _ready():
	var gen = preload("generator.gd")
	_generator = gen.Heightmap.new()
	
	_library.set_atlas_size(4)
	_library.create_voxel(0, "air").set_transparent()
	_library.create_voxel(1, "grass_dirt").set_cube_geometry().set_cube_uv_tbs_sides(Vector2(0,0), Vector2(0,1), Vector2(1,0))
	_library.create_voxel(2, "dirt").set_cube_geometry().set_cube_uv_all_sides(Vector2(1,0))
	_library.create_voxel(3, "log").set_cube_geometry().set_cube_uv_tbs_sides(Vector2(3,0), Vector2(3,0), Vector2(2,0))
	_library.create_voxel(4, "water").set_transparent().set_cube_geometry(15.0/16.0).set_cube_uv_all_sides(Vector2(2,1)).set_material_id(1)
	
	var mesher = get_mesher()
	mesher.set_library(_library)
	mesher.set_material(solid_material, 0)
	mesher.set_material(transparent_material, 1)

	force_load_blocks(Vector3(0,0,0), Vector3(8,3,8))


# TODO option to execute this method in a thread
func _generate_block(voxels, block_pos):
	#print("Generating block " + str(block_pos))
	var offset = block_to_voxel(block_pos)
	_generator.generate(voxels, offset)


