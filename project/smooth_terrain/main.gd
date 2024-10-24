extends Node

@onready var _terrain = $VoxelTerrain
@onready var _avatar = $SpectatorAvatar
@onready var _light = $DirectionalLight

var _process_stats = {}
var _displayed_process_stats = {}
var _time_before_display_process_stats = 1.0

const _process_stat_names = [
	"time_detect_required_blocks",
	"time_io_requests",
	"time_mesh_requests",
	"time_update_task"
]


func _process(delta):
	var stats = _terrain.get_statistics()
	
	DDD.set_text("FPS", Engine.get_frames_per_second())
	DDD.set_text("Static memory", _format_memory(OS.get_static_memory_usage()))
	DDD.set_text("Blocked lods", stats.blocked_lods)
	DDD.set_text("Position", _avatar.position)

	var global_stats = VoxelEngine.get_stats()
	for p in global_stats:
		var pool_stats = global_stats[p]
		for k in pool_stats:
			DDD.set_text(str(p, "_", k), pool_stats[k])

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

	_terrain.debug_set_draw_enabled(true)
	_terrain.debug_set_draw_flag(VoxelLodTerrain.DEBUG_DRAW_MESH_UPDATES, true)


static func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb, ".", mbr, " Mb")


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_O:
					var vp = get_viewport()
					if vp.debug_draw == Viewport.DEBUG_DRAW_DISABLED:
						vp.debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
					else:
						vp.debug_draw = Viewport.DEBUG_DRAW_DISABLED

				KEY_L:
					# Toggle shadows
					_light.shadow_enabled = not _light.shadow_enabled
