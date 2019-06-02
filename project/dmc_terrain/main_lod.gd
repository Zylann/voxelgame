extends Node

onready var _terrain = get_node("VoxelTerrain")
onready var _avatar = get_node("SpectatorAvatar")

var _process_stats = {}
var _displayed_process_stats = {}
var _time_before_display_process_stats = 1.0


func _process(delta):
	var stats = _terrain.get_stats()
	
	for i in len(stats.stream.remaining_blocks_per_thread):
		var remaining = stats.stream.remaining_blocks_per_thread[i]
		DDD.set_text(str("Loading blocks [", i, "]"), str(remaining))

	for i in len(stats.updater.remaining_blocks_per_thread):
		var remaining = stats.updater.remaining_blocks_per_thread[i]
		DDD.set_text(str("Meshing blocks [", i, "]"), str(remaining))

	DDD.set_text("Static memory", _format_memory(OS.get_static_memory_usage()))
	DDD.set_text("Dynamic memory", _format_memory(OS.get_dynamic_memory_usage()))
	DDD.set_text("Blocked lods", stats.blocked_lods)
	DDD.set_text("Load sort time", stats.stream.sorting_time)
	DDD.set_text("Mesh sort time", stats.updater.sorting_time)

	for k in stats.process:
		var v = stats.process[k]
		if k in _process_stats:
			_process_stats[k] = max(_process_stats[k], v)
		else:
			_process_stats[k] = v

	_time_before_display_process_stats -= delta
	if _time_before_display_process_stats < 0:
		_time_before_display_process_stats = 1.0
		_displayed_process_stats = _process_stats
		_process_stats = {}

	for k in _displayed_process_stats:
		DDD.set_text(k, _displayed_process_stats[k])


static func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb, ".", mbr, " Mb")


func _input(event):
	if event is InputEventKey:
		if event.pressed:

			if event.scancode == KEY_M:
				print("Printing map state")
				_print_map_state(_terrain, _avatar.global_transform.origin)

			elif event.scancode == KEY_N:
				pretty_print(_terrain.get_stats())


static func pretty_print(d, depth=0):
	var indent = ""
	for i in depth:
		indent += "    "
	for k in d:
		var v = d[k]
		if typeof(v) == TYPE_DICTIONARY:
			print(indent, k, ": ")
			pretty_print(v, depth + 1)
		else:
			print(indent, k, ": ", d[k])


static func _print_map_state(terrain, avatar_pos):
	var r = terrain.get_block_region_extent()
	var im_w = 2 * r
	var im_h = im_w

	for lod_index in terrain.get_lod_count():
		var avatar_block_pos = terrain.voxel_to_block_position(avatar_pos, lod_index)

		for y in im_h:
			var by = avatar_block_pos.y + y - r

			var im = Image.new()
			im.create(im_w, im_h, false, Image.FORMAT_RGB8)
			im.fill(Color(0, 0, 0))

			im.lock()

			for z in im_w:
				for x in im_h:
					var bx = avatar_block_pos.x + x - r
					var bz = avatar_block_pos.z + z - r

					var info = terrain.get_block_info(Vector3(bx, by, bz), lod_index)

					var col = Color(0.1, 0.1, 0.1)

					if info.loading == 1:
						col = Color(0, 0, 0.5)
					elif info.loading == 2:
						if info.visible:
							if info.meshed:
								col = Color(1, 1, 1)
							else:
								col = Color(1, 0, 0)
						else:
							if info.meshed:
								col = Color(0.5, 0.5, 0.5)
							else:
								col = Color(0.5, 0.0, 0)

					im.set_pixel(x, z, col)

			im.unlock()

			im.resize(im.get_width() * 16, im.get_height() * 16, Image.INTERPOLATE_NEAREST)

			var fname = str("debug_data/lod", lod_index, "_y", y, ".png")
			print("Saving ", fname)
			im.save_png(fname)

	if terrain.has_method("dump_block_history"):
		var history = terrain.dump_block_history()
		var json = JSON.print(history)
		var f = File.new()
		var fname = "debug_data/block_history.json"
		print("Saving ", fname)
		f.open(fname, File.WRITE)
		f.store_string(json)
		f.close()

	print("Done")






