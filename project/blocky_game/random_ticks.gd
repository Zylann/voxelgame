# Implements random cellular automata behavior of the terrain,
# such as growth of grass and crops, fire etc.

extends Node

# Takes effect in a large radius around the player
const RADIUS = 100
# How many voxels are affected per frame
const VOXELS_PER_FRAME = 512

onready var _terrain = get_node("../VoxelTerrain")
onready var _avatar = get_node("../CharacterAvatar")
onready var _voxel_tool = _terrain.get_voxel_tool()

var _grass_dirs = [
	Vector3(-1, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 0, -1),
	Vector3(0, 0, 1),
	Vector3(-1, 0, -1),
	Vector3(1, 0, -1),
	Vector3(-1, 0, 1),
	Vector3(1, 0, 1),
	
	Vector3(-1, 1, 0),
	Vector3(1, 1, 0),
	Vector3(0, 1, -1),
	Vector3(0, 1, 1),
	Vector3(-1, 1, -1),
	Vector3(1, 1, -1),
	Vector3(-1, 1, 1),
	Vector3(1, 1, 1),

	Vector3(-1, -1, 0),
	Vector3(1, -1, 0),
	Vector3(0, -1, -1),
	Vector3(0, -1, 1),
	Vector3(-1, -1, -1),
	Vector3(1, -1, -1),
	Vector3(-1, -1, 1),
	Vector3(1, -1, 1)
]


func _ready():
	_voxel_tool.set_channel(VoxelBuffer.CHANNEL_TYPE)


func _process(delta):
	#var time_before = OS.get_ticks_usec()

	_grass_dirs.shuffle()

	var center = _avatar.transform.origin.floor()
	var r = RADIUS
	var area = AABB(center - Vector3(r, r, r), 2 * Vector3(r, r, r))
	_voxel_tool.run_blocky_random_tick(
		area, VOXELS_PER_FRAME, funcref(self, "_random_tick_callback"), 16)

	#var time_spent = OS.get_ticks_usec() - time_before
	#print("Spent ", time_spent)


func _random_tick_callback(pos: Vector3, value: int):
	if value == 2:
		# Grass
		
		# Dying
		var above = pos + Vector3(0, 1, 0)
		var above_v = _voxel_tool.get_voxel(above)
		if above_v != 0:
			# Turn to dirt
			_voxel_tool.set_voxel(pos, 1)
		else:
			# Spread
			var attempts = 1
			var ra = randf()
			if ra < 0.15:
				attempts = 2
				if ra < 0.03:
					attempts = 3
	
			for i in attempts:
				for di in len(_grass_dirs):
					var npos = pos + _grass_dirs[di]
					var nv = _voxel_tool.get_voxel(npos)
					if nv == 1:
						var above_neighbor = _voxel_tool.get_voxel(npos + Vector3(0, 1, 0))
						if above_neighbor == 0:
							_voxel_tool.set_voxel(npos, 2)
							break
