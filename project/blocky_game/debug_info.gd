extends Node

onready var _terrain = get_parent().get_node("VoxelTerrain")


func _process(delta):
	var dm = OS.get_dynamic_memory_usage()
	var sm = OS.get_static_memory_usage()

	DDD.set_text("Dynamic memory", _format_memory(dm))
	DDD.set_text("Static memory", _format_memory(sm))

	var global_stats = VoxelServer.get_stats()
	for p in [[global_stats.streaming, "streaming_"], [global_stats.meshing, "meshing_"]]:
		var pool_stats = p[0]
		var prefix = p[1]
		for k in pool_stats:
			DDD.set_text(str(prefix, k), pool_stats[k])

	var terrain_stats = _terrain.get_statistics()
	DDD.set_text("Main thread block updates", terrain_stats.remaining_main_thread_blocks)


static func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb, ".", mbr, " Mb")
