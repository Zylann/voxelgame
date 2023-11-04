
# Test generating a single column without using threads

extends Node

# TODO Can't preload script: https://github.com/godotengine/godot/issues/83125
#const TestGenerator = preload("./multipass_generator.gd")
const GeneratorResource = preload("./multipass_generator.tres")
const BlockyMesher = preload("./blocky_mesher.tres")


func _ready():
	var generator := GeneratorResource
	
	var column = generator.debug_generate_test_column(Vector2i(2,1))
	
	# TODO Need to preload script...
	var channel := 0#TestGenerator.CHANNEL
	
	var mesher := BlockyMesher
	mesher.library.bake()
	var materials : Array[Material] = mesher.library.get_materials()
	
	var origin_in_voxels := Vector3(0, generator.column_base_y_blocks * 16, 0)
	
	for rby in column.size():
		var block : VoxelBuffer = column[rby]
		
		var padded_voxels := VoxelBuffer.new()
		var bs := block.get_size()
		padded_voxels.create(bs.x + 2, bs.y + 2, bs.z + 2)
		padded_voxels.copy_channel_from_area(block, Vector3i(), bs, Vector3i(1, 1, 1), channel)
		
		if rby > 0:
			var bottom_block : VoxelBuffer = column[rby - 1]
			padded_voxels.copy_channel_from_area(bottom_block, 
				Vector3i(0, bs.y - 1, 0), bs, Vector3i(1, 0, 1), channel)

		if rby + 1 < column.size():
			var top_block : VoxelBuffer = column[rby + 1]
			padded_voxels.copy_channel_from_area(top_block, 
				Vector3i(), Vector3i(bs.x, 1, bs.z), Vector3i(1, bs.y + 1, 1), channel)
		
		# print("---- Block ", rby)
		# for z in [8]:
		# 	var ds := ""
		# 	for x in block.get_size().x:
		# 		for y in block.get_size().y:
		# 			ds += str(block.get_voxel(x, y, z, 0), " ")
		# 		ds += "\n"
		# 	print("Z ", z)
		# 	print(ds)
		
		var mesh := mesher.build_mesh(padded_voxels, materials)
		
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = origin_in_voxels
		add_child(mi)
		
		origin_in_voxels.y += bs.y

