
const Structure = preload("./structure.gd")


var trunk_len_min := 6
var trunk_len_max := 15
var log_type := 1
var leaves_type := 2
var channel := VoxelBuffer.CHANNEL_TYPE


func generate() -> Structure:
	var voxels := {}
	# Let's make crappy trees
	
	# Trunk
	var trunk_len := int(randf_range(trunk_len_min, trunk_len_max))
	for y in trunk_len:
		voxels[Vector3(0, y, 0)] = log_type

	# Branches
	var branches_start := int(randf_range(trunk_len / 3, trunk_len / 2))
	for y in range(branches_start, trunk_len):
		var t := float(y - branches_start) / float(trunk_len)
		var branch_chance := 1.0 - pow(t - 0.5, 2)
		if randf() < branch_chance:
			var branch_len := int((trunk_len / 2.0) * branch_chance * randf())
			var pos := Vector3(0, y, 0)
			var angle := randf_range(-PI, PI)
			var dir := Vector3(cos(angle), 0.45, sin(angle))
			for i in branch_len:
				pos += dir
				var ipos = pos.round()
				voxels[ipos] = log_type

	# Leaves
	var log_positions := voxels.keys()
	log_positions.shuffle()
	var leaf_count := int(0.75 * len(log_positions))
	log_positions.resize(leaf_count)
	var dirs := [
		Vector3(-1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(0, 0, -1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(0, -1, 0)
	]
	for c in leaf_count:
		var pos = log_positions[c]
		if pos.y < branches_start:
			continue
		for di in len(dirs):
			var npos = pos + dirs[di]
			if not voxels.has(npos):
				voxels[npos] = leaves_type

	# Make structure
	var aabb := AABB()
	for pos in voxels:
		aabb = aabb.expand(pos)

	var structure := Structure.new()
	structure.offset = -aabb.position

	var buffer := structure.voxels
	buffer.create(int(aabb.size.x) + 1, int(aabb.size.y) + 1, int(aabb.size.z) + 1)

	for pos in voxels:
		var rpos = pos + structure.offset
		var v = voxels[pos]
		buffer.set_voxel(v, rpos.x, rpos.y, rpos.z, channel)

	return structure

