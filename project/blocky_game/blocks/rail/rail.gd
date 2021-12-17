extends "../block.gd"

const Util = preload("res://common/util.gd")
const Blocks = preload("../blocks.gd")

const _STRAIGHT = 0
const _TURN = 2
const _SLOPE = 6

const AXIS_X = 0
const AXIS_Z = 1

const _dir_to_axis = [
	AXIS_X,
	AXIS_X,
	AXIS_Z,
	AXIS_Z
]

const _all_directions = [
	Blocks.ROTATION_Y_NEGATIVE_X,
	Blocks.ROTATION_Y_POSITIVE_X,
	Blocks.ROTATION_Y_NEGATIVE_Z,
	Blocks.ROTATION_Y_POSITIVE_Z
]

# TODO This should have work as `const`, it broke in Godot4
# For each variant, what are their connection directions
var _variant_connection_dirs = [
	[Blocks.ROTATION_Y_NEGATIVE_X, Blocks.ROTATION_Y_POSITIVE_X], # straight_x
	[Blocks.ROTATION_Y_NEGATIVE_Z, Blocks.ROTATION_Y_POSITIVE_Z], # straight_z
	
	[Blocks.ROTATION_Y_NEGATIVE_X, Blocks.ROTATION_Y_POSITIVE_Z], # turn_nx
	[Blocks.ROTATION_Y_POSITIVE_X, Blocks.ROTATION_Y_NEGATIVE_Z], # turn_px
	[Blocks.ROTATION_Y_NEGATIVE_Z, Blocks.ROTATION_Y_NEGATIVE_X], # turn_nz
	[Blocks.ROTATION_Y_POSITIVE_Z, Blocks.ROTATION_Y_POSITIVE_X], # turn_px

	[Blocks.ROTATION_Y_NEGATIVE_X, Blocks.ROTATION_Y_POSITIVE_X], # slope_nx
	[Blocks.ROTATION_Y_NEGATIVE_X, Blocks.ROTATION_Y_POSITIVE_X], # slope_px
	[Blocks.ROTATION_Y_NEGATIVE_Z, Blocks.ROTATION_Y_POSITIVE_Z], # slope_nz
	[Blocks.ROTATION_Y_NEGATIVE_Z, Blocks.ROTATION_Y_POSITIVE_Z], # slope_pz
]

# Index is a bitmask of connecting directions.
# In ambiguous cases, we either choose the most represented axis,
# or return -1 to mean that we should fallback on a default behavior.
const _auto_orient_table = [               # -x | +x | -z | +z
	-1,                                    #  -    -    -    -
	AXIS_X,                                #  X    -    -    -
	AXIS_X,                                #  -    X    -    -
	AXIS_X,                                #  X    X    -    -
	AXIS_Z,                                #  -    -    X    -
	_TURN + Blocks.ROTATION_Y_NEGATIVE_Z,  #  X    -    X    -
	_TURN + Blocks.ROTATION_Y_POSITIVE_X,  #  -    X    X    -
	AXIS_X,                                #  X    X    X    - (ambiguous)
	AXIS_Z,                                #  -    -    -    X            
	_TURN + Blocks.ROTATION_Y_NEGATIVE_X,  #  X    -    -    X
	_TURN + Blocks.ROTATION_Y_POSITIVE_Z,  #  -    X    -    X
	_TURN + Blocks.ROTATION_Y_POSITIVE_Z,  #  X    X    -    X (ambiguous)
	AXIS_Z,                                #  -    -    X    X
	AXIS_Z,                                #  X    -    X    X (ambiguous)
	AXIS_Z,                                #  -    X    X    X (ambiguous)
	-1                                     #  X    X    X    X (ambiguous)
]


func _get_blocks() -> Blocks:
	return get_parent() as Blocks


func place(voxel_tool: VoxelTool, pos: Vector3, look_dir: Vector3):
	# This is a fairly complicated routine, but it shouldnt be called often

	# Get rails around the placed one
	var neighbors := _find_neighbor_rails(voxel_tool, pos, _all_directions)		
	
	# Filter out rails that are already part of a stretch
	var available_neighbors := {}
	for di in neighbors:
		var neighbor : Dictionary = neighbors[di]
		var neighbor_variant_index : int = neighbor.group + neighbor.rotation
		var cdirs := _find_connected_directions_from_variant(
			voxel_tool, neighbor.pos, neighbor_variant_index)
		# Rails have two endpoints, so we keep only those with a free endpoint.
		if len(cdirs) < 2:
			neighbor["connected_dirs"] = cdirs
			available_neighbors[di] = neighbor
	
	# Orient and place rail
	var variant_index := _get_auto_oriented_variant(pos, available_neighbors, look_dir)
	voxel_tool.set_voxel(pos, base_info.voxels[variant_index])
	
	# Orient neighbors
	for di in available_neighbors:
		var neighbor = available_neighbors[di]
		var connected_dirs = neighbor["connected_dirs"]
		assert(len(connected_dirs) < 2)

		# Add one direction to the neighbor coming to the placed rail,
		# preserving the other connection if it had one
		var opposite_di := Blocks.get_opposite_y_dir(di)
		connected_dirs.append(opposite_di)

		var nn := _find_neighbor_rails(voxel_tool, neighbor.pos, connected_dirs)
		var neighbor_variant_index := _get_auto_oriented_variant(neighbor.pos, nn, Vector3())
		voxel_tool.set_voxel(neighbor.pos, base_info.voxels[neighbor_variant_index])


func _get_auto_oriented_variant(
	pos: Vector3, neighbors: Dictionary, look_dir: Vector3) -> int:

	var mask := 0
	for di in neighbors:
		mask |= (1 << di)
	var variant_index : int = _auto_orient_table[mask]
	if variant_index == -1:
		variant_index = _get_axis_from_look(look_dir)

	# Convert to slope if needed
	var group = _get_group_from_index(variant_index)
	if group == _STRAIGHT:
		var connecting_dirs = _variant_connection_dirs[variant_index]
		for di in connecting_dirs:
			if neighbors.has(di):
				var neighbor = neighbors[di]
				if pos.y < neighbor.pos.y:
					variant_index = _SLOPE + di
					break

	return variant_index


func _find_neighbor_rails(voxel_tool: VoxelTool, pos: Vector3, direction_list: Array) -> Dictionary:
	var neighbors := {}
	var blocks := _get_blocks()

	# We only want to keep one rail per direction.
	# Priority is given to rails at the same level, then upward, then downward.
	# If there is both an upward and downward neighbor, the upper one takes priority,
	# because such rail would need a support block below, obstructing access to the lower one.
	for dy in [0, 1, -1]:
		for di in direction_list:
			if neighbors.has(di):
				continue
			var npos := pos + Blocks.get_y_dir_vec(di)
			npos.y += dy
			var nv := voxel_tool.get_voxel(npos)
			var nrm := blocks.get_raw_mapping(nv)

			if nrm.block_id == base_info.id:
				var group := _get_group_from_index(nrm.variant_index)
				# Decode rail
				neighbors[di] = {
					"id": nrm.block_id,
					"group": group,
					"rotation": nrm.variant_index - group,
					"pos": npos
				}

	return neighbors


# Finds the list of directions in which the rail has connected neighbors
func _find_connected_directions_from_variant(
	voxel_tool: VoxelTool, rail_pos: Vector3, variant_index: int) -> Array:

	var dirs : Array = _variant_connection_dirs[variant_index]
	var neighbors := _find_neighbor_rails(voxel_tool, rail_pos, dirs)
	var connected_dirs := []

	for di in neighbors:
		var neighbor = neighbors[di]
		var neighbor_variant = neighbor.group + neighbor.rotation
		var neighbor_dirs = _variant_connection_dirs[neighbor_variant]

		assert(len(neighbor_dirs) == 2)

		# Check if one of the two ends is connected to our rail
		for ndi in neighbor_dirs:
			var opposite = Blocks.get_opposite_y_dir(ndi)
			if opposite in dirs:
				connected_dirs.append(di)
				break

	return connected_dirs


static func _get_group_from_index(i: int) -> int:
	if i < _TURN:
		return _STRAIGHT
	if i < _SLOPE:
		return _TURN
	return _SLOPE


static func _get_axis_from_look(dir: Vector3) -> int:
	var a = Util.get_direction_id4(Vector2(dir.x, dir.z))
	match a:
		0:
			return AXIS_X
		1:
			return AXIS_Z
		2:
			return AXIS_X
		3:
			return AXIS_Z
		_:
			assert(false)
	return -1
