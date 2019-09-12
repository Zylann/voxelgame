extends Label

# Deferred because stats are reset everytime the terrain is processing,
# so we make sure we get them always at the same point in time
var _deferred_print_stats = false
var _span_timer = 0.0
var _span_timer_interval = 0.5
var _previous_file_count = 0
var _previous_time_spent_opening_files = 0
var _file_openings_per_second = 0
var _time_spent_opening_files_per_second = 0


func _process(delta):
	var dm = OS.get_dynamic_memory_usage()
	var sm = OS.get_static_memory_usage()

	var terrain = get_parent().get_node("VoxelTerrain")
	var stats = terrain.get_statistics()

	var s = str("Dynamic memory: ", _format_memory(dm), \
		"\nStatic memory: ", _format_memory(sm))

	for i in len(stats.stream.remaining_blocks_per_thread):
		s += str("\nStream[", i, "]: ", stats.stream.remaining_blocks_per_thread[i])

	for i in len(stats.updater.remaining_blocks_per_thread):
		s += str("\nUpdater[", i, "]: ", stats.updater.remaining_blocks_per_thread[i])

	s += str("\nMain thread block updates: ", stats.remaining_main_thread_blocks)

	_span_timer -= delta
	if _span_timer <= 0.0:
		_span_timer = _span_timer_interval

		var file_openings = stats.stream.file_openings
		var time_spent_opening_files = stats.stream.time_spent_opening_files

		_file_openings_per_second = int((file_openings - _previous_file_count) / _span_timer)
		_time_spent_opening_files_per_second = int((time_spent_opening_files - _previous_time_spent_opening_files) / _span_timer)

		_previous_file_count = file_openings
		_previous_time_spent_opening_files = time_spent_opening_files

	s += str("\nFile openings per second: ", _file_openings_per_second)
	s += str("\nTime spent opening files per second: ", _time_spent_opening_files_per_second, " us")

	set_text(s)

	#if stats.updater.mesh_alloc_time > 15:
	#	print("Mesh alloc time is ", stats.updater.mesh_alloc_time, " for ", stats.updater.updated_blocks)

	if _deferred_print_stats:
		_deferred_print_stats = false

		print(str("Time stats:", \
			"\t\n", "time_detect_required_blocks:    ", stats.time_detect_required_blocks, " usec", \
			"\t\n", "time_request_blocks_to_load:    ", stats.time_request_blocks_to_load, " usec", \
			"\t\n", "time_process_load_responses:    ", stats.time_process_load_responses, " usec", \
			"\t\n", "time_request_blocks_to_update:  ", stats.time_request_blocks_to_update, " usec", \
			"\t\n", "time_process_update_responses:  ", stats.time_process_update_responses, " usec", \
			"\t\n"))


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_F4:
				_deferred_print_stats = true


func _draw():
	if not Input.is_key_pressed(KEY_F3):
		return
	var terrain = get_parent().get_node("VoxelTerrain")
	var avatar = get_parent().get_node("CharacterAvatar")

	var center_bpos = terrain.voxel_to_block(avatar.translation)
	var ry = 1
	var rx = 20
	var rz = 20

	var gui_origin = Vector2(400, 100)
	var a = 0.3
	var w = 4

	for y in range(-ry, ry):
		for z in range(-rz, rz):
			for x in range(-rx, rx):

				var bpos = center_bpos + Vector3(x, y, z)
				var state = terrain.get_block_state(bpos)
				var col

				match state:
					VoxelTerrain.BLOCK_NONE:
						col = Color(0, 0, 0, a)

					VoxelTerrain.BLOCK_LOAD:
						col = Color(1, 0, 0, a)

					VoxelTerrain.BLOCK_UPDATE_NOT_SENT, \
					VoxelTerrain.BLOCK_UPDATE_SENT:
						col = Color(1, 0.5, 0, a)

					_:
						col = Color(1, 1, 1, a)

				draw_rect(Rect2(gui_origin + Vector2(x, z) * w, Vector2(w, w)), col)


static func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb, ".", mbr, " Mb")
