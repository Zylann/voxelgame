
extends VoxelTerrain

#const CustomProvider = preload("provider.gd")

export(Material) var solid_material = null
export(Material) var transparent_material = null

var _library = VoxelLibrary.new()
var _generator = null


func _ready():
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
	
	#set_provider(CustomProvider.new())
	var provider = VoxelProviderTest.new()
	provider.set_mode(VoxelProviderTest.MODE_WAVES)
	provider.set_pattern_size(Vector3(10,20,10))
	set_provider(provider)
#	var map = get_map()
#	for x in range(0, 50):
#		for y in range(0, 50):
#			for z in range(0, 50):
#				var v = 0
#				if randf() < 0.1:
#					v = 1+randi()%2
#				map.set_voxel(v, x, y-10, z)
#	map.set_voxel(0, 50,50,50)

	force_load_blocks(Vector3(0,0,0), Vector3(12,4,12))
#	var Testouille = preload("debug_camera.gd")
#	var t = Testouille.new()
#	t.lolance()


