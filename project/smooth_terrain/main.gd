extends Node

const Util = preload("res://common/util.gd")

onready var _terrain = get_node("VoxelTerrain")
onready var _avatar = get_node("SpectatorAvatar")
onready var _camera = get_node("SpectatorAvatar/Camera")
onready var _light = get_node("DirectionalLight")

var _process_stats = {}
var _displayed_process_stats = {}
var _time_before_display_process_stats = 1.0
var _block_highlights = []
var _first_process_time = -1.0
var _first_time_no_blocked_lods = -1.0
var _process_count = 0

const _process_stat_names = [
	"time_detect_required_blocks",
	"time_request_blocks_to_load",
	"time_process_load_responses",
	"time_request_blocks_to_update",
	"time_process_update_responses",
	"updated_blocks"
]


func _ready():
	#test_downscale()
	pass


static func test_downscale():
	var vb = VoxelBuffer.new()
	vb.create(16, 16, 16)
	var vb2 = VoxelBuffer.new()
	vb2.create(16, 16, 16)
	for z in 16:
		for x in 16:
			for y in 16:
				vb.set_voxel_f(2.0 * randf() - 0.1, x, y, z, VoxelBuffer.CHANNEL_SDF)
				var d = Vector3(x, y, z).distance_to(Vector3(8,8,8)) - 7
				vb2.set_voxel_f(d, x, y, z, VoxelBuffer.CHANNEL_SDF)
	vb2.downscale_to(vb, Vector3(), vb2.get_size(), Vector3(0,8,0))
	var im = vb.debug_print_sdf_top_down()
	im.save_png("downscale_test.png")
	im = vb2.debug_print_sdf_top_down()
	im.save_png("downscale_test_src.png")


func _process(delta):
	if _first_process_time < 0:
		_first_process_time = OS.get_ticks_msec()

	var stats = _terrain.get_statistics()
	
	for i in len(stats.stream.remaining_blocks_per_thread):
		var remaining = stats.stream.remaining_blocks_per_thread[i]
		DDD.set_text(str("Loading blocks [", i, "]"), str(remaining))

	for i in len(stats.updater.remaining_blocks_per_thread):
		var remaining = stats.updater.remaining_blocks_per_thread[i]
		DDD.set_text(str("Meshing blocks [", i, "]"), str(remaining))

	DDD.set_text("FPS", Engine.get_frames_per_second())
	DDD.set_text("Main thread block updates", stats.remaining_main_thread_blocks)
	DDD.set_text("Static memory", _format_memory(OS.get_static_memory_usage()))
	DDD.set_text("Dynamic memory", _format_memory(OS.get_dynamic_memory_usage()))
	DDD.set_text("Blocked lods", stats.blocked_lods)
	DDD.set_text("Load sort time", stats.stream.sorting_time)
	DDD.set_text("Mesh sort time", stats.updater.sorting_time)
	DDD.set_text("Position", _avatar.translation)

	if _first_time_no_blocked_lods < 0 and stats.blocked_lods == 0 and _process_count > 200:
		_first_time_no_blocked_lods = OS.get_ticks_msec()
		var load_time = _first_time_no_blocked_lods - _first_process_time
		print("Time to reach full load: ", float(load_time) / 1000.0, " seconds")
		print("First process time: ", _first_process_time)
		print(stats)

	for k in _process_stat_names:
		var v = stats[k]
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

	#debug_pointed_block()
	#if Input.is_key_pressed(KEY_SPACE):
	#debug_show_octrees()

	_process_count += 1


func debug_show_octrees():
	var octrees = _terrain.debug_get_octrees()
	var octree_side = _terrain.get_block_size() << (_terrain.get_lod_count() - 1)
	var octree_size = Vector3(1,1,1) * octree_side
	var r = octree_side * 2
	var pad = Vector3(1,1,1)
	var ppos = _camera.global_transform.origin #_avatar.translation
	for pos in octrees:
		var wpos = pos * octree_size
		if ppos.distance_to(wpos) < r:
			DDD.draw_box(wpos + pad, octree_size - 2 * pad, Color(0,1,0))


func debug_pointed_block():

	var ray_origin = _camera.global_transform.origin
	var ray_dir = -_camera.global_transform.basis.z
	var hits = _terrain.debug_raycast_block(ray_origin, ray_dir)

	if len(hits) > 0:
		var d = hits[0]
		for k in d:
			DDD.set_text(str("Pointed block ", k), d[k])

	for mi in _block_highlights:
		mi.hide()

	for i in len(hits):
		var d = hits[i]
		
		var mi
		if i < len(_block_highlights):
			mi = _block_highlights[i]
		else:
			mi = MeshInstance.new()
			var mesh = Util.create_wirecube_mesh()
			mi.mesh = mesh
			var mat = SpatialMaterial.new()
			mat.flags_unshaded = true
			mat.vertex_color_use_as_albedo = true
			mi.material_override = mat
			add_child(mi)
			_block_highlights.append(mi)

		var pad = 0.1 * d.lod
		var scale = (16 << d.lod)
		mi.translation = d.position * scale - Vector3(pad, pad, pad)
		mi.scale = Vector3(scale, scale, scale) + pad * Vector3(2, 2, 2)
		mi.show()


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
				pretty_print(_terrain.get_statistics())

			elif event.scancode == KEY_P:
				get_tree().get_root().print_tree_pretty()

			elif event.scancode == KEY_O:
				var vp = get_viewport()
				if vp.debug_draw == Viewport.DEBUG_DRAW_DISABLED:
					vp.debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
				else:
					vp.debug_draw = Viewport.DEBUG_DRAW_DISABLED

			elif event.scancode == KEY_L:
				_light.shadow_enabled = not _light.shadow_enabled


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






