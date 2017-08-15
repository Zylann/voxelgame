
extends VoxelTerrain

func _ready():
	# TODO Should be in editor
	var mesher = get_mesher()
	mesher.set_occlusion_enabled(true)
	mesher.set_occlusion_darkness(1.0)
	
