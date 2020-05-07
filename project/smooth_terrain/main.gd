extends Node

onready var _terrain = $VoxelTerrain
onready var _avatar = $SpectatorAvatar
onready var _light = $DirectionalLight

var _process_stats = {}
var _displayed_process_stats = {}
var _time_before_display_process_stats = 1.0

const _process_stat_names = [
	"time_detect_required_blocks",
	"time_request_blocks_to_load",
	"time_process_load_responses",
	"time_request_blocks_to_update",
	"time_process_update_responses",
	"updated_blocks"
]


func _process(delta):
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


static func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb, ".", mbr, " Mb")


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.scancode:
				KEY_O:
					var vp = get_viewport()
					if vp.debug_draw == Viewport.DEBUG_DRAW_DISABLED:
						vp.debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
					else:
						vp.debug_draw = Viewport.DEBUG_DRAW_DISABLED

				KEY_L:
					# Toggle shadows
					_light.shadow_enabled = not _light.shadow_enabled


