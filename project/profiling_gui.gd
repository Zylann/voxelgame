extends Label


func _input(event):
	if event.type == InputEvent.KEY and event.pressed == false:
		if event.scancode == KEY_F4:
			var terrain = get_parent().get_node("VoxelTerrain")
			if terrain.has_method("get_profiling_info") == false:
				return
			var terrain_infos = terrain.get_profiling_info()
			var mesher_infos = terrain.get_mesher().get_profiling_info()
			save_json(terrain_infos, "profiling_terrain.json")
			save_json(mesher_infos, "profiling_mesher.json")


func save_json(infos, path):
	var f = File.new()
	var ret = f.open(path, File.WRITE)
	if ret == 0:
		f.store_string(to_json(infos))
		f.close()
	else:
		print("Could not dump profiling info (error " + str(ret) + ")")

