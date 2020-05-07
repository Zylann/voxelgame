extends Node

onready var _terrain = get_parent().get_node("VoxelTerrain")


func _process(delta):
	var dm = OS.get_dynamic_memory_usage()
	var sm = OS.get_static_memory_usage()

	var stats = _terrain.get_statistics()
	
	DDD.set_text("Dynamic memory", _format_memory(dm))
	DDD.set_text("Static memory", _format_memory(sm))

	for i in len(stats.stream.remaining_blocks_per_thread):
		DDD.set_text(str("Stream[", i, "]"), stats.stream.remaining_blocks_per_thread[i])

	for i in len(stats.updater.remaining_blocks_per_thread):
		DDD.set_text(str("Updater[", i, "]"), stats.updater.remaining_blocks_per_thread[i])

	DDD.set_text("Main thread block updates", stats.remaining_main_thread_blocks)


static func _format_memory(m):
	var mb = m / 1000000
	var mbr = m % 1000000
	return str(mb, ".", mbr, " Mb")
