extends Node

var _action_place = false
var _action_remove = false
var _head = null
var _terrain = null


func _ready():
	_head = get_parent().get_node("Camera")
	_terrain = get_parent().get_parent().get_node("VoxelTerrain")


func _input(event):
	return
	if not Input.is_key_pressed(KEY_CONTROL):
		return
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				_action_place = true
			elif event.button_index == BUTTON_RIGHT:
				_action_remove = true

	elif event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_P:
				print_map_slice()


func _process(delta):

	var head_trans = _head.global_transform
	var pointed_pos = head_trans.origin - 6.0 * head_trans.basis.z

	if _action_place:
		do_sphere(pointed_pos, 3.5, true)
	elif _action_remove:
		do_sphere(pointed_pos, 3.5, false)

	_action_place = false
	_action_remove = false


func do_sphere(center, fradius, add):
	var storage = _terrain.get_storage()
	var r = int(floor(fradius)) + 2
	var channel = VoxelBuffer.CHANNEL_ISOLEVEL
	
	var xc = int(floor(center.x))
	var yc = int(floor(center.y))
	var zc = int(floor(center.z))
		
	for zi in range(-r, r):
		for xi in range(-r, r):
			for yi in range(-r, r):
				var x = xi + xc
				var y = yi + yc
				var z = zi + zc
				var pos = Vector3(x, y, z)
				var d = pos.distance_to(center) - fradius
				var e = storage.get_voxel_f(x, y, z, channel)
				var res
				if add:
					res = min(d, e)
				else:
					res = max(d, e)
				#print(res)
				storage.set_voxel_f(res, x, y, z, channel)

	_terrain.make_area_dirty(AABB(center - Vector3(r,r,r), 2*Vector3(r,r,r)))


func print_map_slice():
	var storage = _terrain.get_storage()
	var h = 8
	var r = 16
	var pos = _head.global_transform.origin
	var buffer = VoxelBuffer.new()
	buffer.create(2*r, h, 2*r)
	var channel = VoxelBuffer.CHANNEL_ISOLEVEL
	
	var minp = pos - Vector3(r, h/2, r)
	#print("Printing ", minp, " ; ", buffer.get_size())
	#storage.get_buffer_copy(minp, buffer, channel)
	
	for rx in buffer.get_size_x():
		for ry in buffer.get_size_y():
			for rz in buffer.get_size_z():
				var x = rx + int(minp.x)
				var y = ry + int(minp.y)
				var z = rz + int(minp.z)
				var v = storage.get_voxel_f(x, y, z, channel)
				buffer.set_voxel_iso(v, rx, ry, rz, channel)

	print("Going to print")
	print_buffer_to_images(buffer, channel, "isolevel", 10)


static func print_buffer_to_images(voxels, channel, fname, upscale):
	
	for y in voxels.get_size_y():
		
		var im = Image.new()
		im.create(voxels.get_size_x(), voxels.get_size_z(), false, Image.FORMAT_RGB8)

		im.lock()

		for z in voxels.get_size_z():
			for x in voxels.get_size_x():
				var r = 0.5 * voxels.get_voxel_iso(x, y, z, channel) + 0.5
				if r < 0.5:
					im.set_pixel(x, z, Color(r, r, r*0.5 + 0.5))
				else:
					im.set_pixel(x, z, Color(r, r, r))

		im.unlock()

		if upscale > 1:
			im.resize(im.get_width() * upscale, im.get_height() * upscale, Image.INTERPOLATE_NEAREST)

		var fname_png = str(fname, "_", y, ".png")
		print("Saved ", fname_png)
		im.save_png(fname_png)

	print("Printed")


