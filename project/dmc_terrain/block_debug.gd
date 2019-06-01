extends Control

onready var _terrain = get_node("../VoxelTerrain")

export var block_y_offset = 0
var _lod_index = 1


func _process(delta):
	update()
	DDD.set_text("Debugged LOD", _lod_index)


func _input(event):
	if event is InputEventKey:
		if event.pressed:

			if event.scancode == KEY_KP_8:
				_lod_index += 1
				if _lod_index >= _terrain.get_lod_count():
					_lod_index = _terrain.get_lod_count() - 1

			elif event.scancode == KEY_KP_2:
				_lod_index -= 1
				if _lod_index < 0:
					_lod_index = 0

			elif event.scancode == KEY_H:
				visible = not visible
				set_process(visible)


func draw_block_overlaps():
	var ts0 = 8
	var block_range_lod0 = 32
	
	var viewer = _terrain.get_node(_terrain.viewer_path)
	var viewer_pos = viewer.global_transform.origin
	var viewer_block_pos_lod0 = _terrain.voxel_to_block_position(viewer_pos, 0)
	var by0 = int(viewer_block_pos_lod0.y) + block_y_offset
	var lod_count = _terrain.get_lod_count()

	draw_rect(Rect2(0, 0, ts0 * block_range_lod0, ts0 * block_range_lod0), Color(0,0,0))

	for lod_index in lod_count:
		var block_range = block_range_lod0 >> lod_index
		var red = float(lod_index) / float(lod_count)
		for bz in block_range:
			for bx in block_range:
				var by = by0 >> lod_index
				var ts = ts0 << lod_index
				var info = _terrain.get_block_info(Vector3(bx, by, bz), lod_index)
				if info.visible:
					draw_rect(Rect2(bx * ts, bz * ts, ts, ts), Color(red, 1, 1, 0.5))


func _draw():
	draw_block_states()
	#draw_block_overlaps()


func draw_block_states():
	var ts = 8
	
	var viewer = _terrain.get_node(_terrain.viewer_path)
	var viewer_pos = viewer.global_transform.origin
	var viewer_block_pos = _terrain.voxel_to_block_position(viewer_pos, _lod_index)
	var by = int(viewer_block_pos.y) + block_y_offset
	
	for bz in 32:
		for bx in 32:
			
			var info = _terrain.get_block_info(Vector3(bx, by, bz), _lod_index)
		
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

			# Flickering states
			var now_ms = OS.get_ticks_msec()
			var now = float(now_ms) / 1000.0
			var ftime = float(info.debug_unexpected_drop_time) / 1000.0
			var ft = 1.0 - clamp(now - ftime, 0.0, 1.0)
			if ft > 0.0:
				var fcolor = Color(1, 0, 1)
				if (now_ms / 100) % 2 == 0:
					fcolor = Color(0, 0, 0)
				col = col.linear_interpolate(fcolor, ft)
			
			draw_rect(Rect2(bx * ts, bz * ts, ts, ts), col)
