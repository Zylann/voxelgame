extends Label


func _input(event):
	if event is InputEventKey and event.pressed == false:
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


func _process(delta):
	var dm = OS.get_dynamic_memory_usage()
	var sm = OS.get_static_memory_usage()
	set_text(_format_memory(dm) + "\n" + _format_memory(sm))


func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb) + "." + str(mbr) + " Mb"
