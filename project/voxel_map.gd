
extends VoxelTerrain

#const CustomProvider = preload("provider.gd")


func _ready():
	
	var lib = VoxelLibrary.new()

	lib.set_atlas_size(4)
	
	lib.create_voxel(0, "air").set_transparent()
	
	lib.create_voxel(1, "grass_dirt") \
		.set_cube_geometry() \
		.set_cube_uv_tbs_sides(Vector2(0,0), Vector2(0,1), Vector2(1,0))
	
	lib.create_voxel(2, "dirt") \
		.set_cube_geometry() \
		.set_cube_uv_all_sides(Vector2(1,0))
	
	lib.create_voxel(3, "log") \
		.set_cube_geometry() \
		.set_cube_uv_tbs_sides(Vector2(3,0), Vector2(3,0), Vector2(2,0))
	
	lib.create_voxel(4, "water") \
		.set_transparent() \
		.set_cube_geometry(15.0/16.0) \
		.set_cube_uv_all_sides(Vector2(2,1)) \
		.set_material_id(1)
	
	#set_voxel_library(lib)

	var mesher = get_mesher()
	mesher.set_occlusion_enabled(true)
	mesher.set_occlusion_darkness(1.0)
	
