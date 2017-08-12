
extends VoxelTerrain

const CustomProvider = preload("provider.gd")

export(Material) var solid_material = null
export(Material) var transparent_material = null

var _library = VoxelLibrary.new()
var _generator = null


func _ready():
	
	_library.set_atlas_size(4)
	
	_library.create_voxel(0, "air").set_transparent()
	
	_library.create_voxel(1, "grass_dirt") \
		.set_cube_geometry() \
		.set_cube_uv_tbs_sides(Vector2(0,0), Vector2(0,1), Vector2(1,0))
	
	_library.create_voxel(2, "dirt") \
		.set_cube_geometry() \
		.set_cube_uv_all_sides(Vector2(1,0))
	
	_library.create_voxel(3, "log") \
		.set_cube_geometry() \
		.set_cube_uv_tbs_sides(Vector2(3,0), Vector2(3,0), Vector2(2,0))
	
	_library.create_voxel(4, "water") \
		.set_transparent() \
		.set_cube_geometry(15.0/16.0) \
		.set_cube_uv_all_sides(Vector2(2,1)) \
		.set_material_id(1)
	
	var mesher = get_mesher()
	mesher.set_library(_library)
	mesher.set_material(solid_material, 0)
	#mesher.set_material(transparent_material, 1)
	mesher.set_occlusion_enabled(true)
	mesher.set_occlusion_darkness(1.0)
	
	set_generate_collisions(true)
	set_viewer(get_parent().get_node("CharacterAvatar").get_path())
	
	#set_provider(CustomProvider.new())
	var provider = VoxelProviderTest.new()
	provider.set_mode(VoxelProviderTest.MODE_WAVES)
	provider.set_pattern_size(Vector3(10,8,10))
	set_provider(provider)
	
	make_blocks_dirty(Vector3(-8,-4,-8), Vector3(17,9,17))
	#make_blocks_dirty(Vector3(-16,-8,-16), Vector3(33,17,33))
