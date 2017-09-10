tool
extends VoxelProvider


class OsnNoise:
    var iamaproxy = null
class OsnFractalNoise:
    var iamaproxy = null


var _noise = OsnNoise.new()
var _noise2 = OsnNoise.new()
var channel = Voxel.CHANNEL_TYPE
var _image = preload("res://noise_distorted.png")


func _init():
#	_noise.set_seed(131183)
#	_noise2.set_seed(_noise.get_seed() + 1)
	_image = _image.get_data()


func emerge_block(out_buffer, origin_in_voxels):
	emerge_block_im(out_buffer, origin_in_voxels)


func emerge_block_im(out_buffer, origin_in_voxels):
	var ox = int(floor(origin_in_voxels.x))
	var oy = int(floor(origin_in_voxels.y))
	var oz = int(floor(origin_in_voxels.z))
	
	_image.lock()
	var im_w = _image.get_width()
	var im_h = _image.get_height()
	var im_wm = im_w - 1
	var im_hm = im_h - 1
	
	var x = 0
	var z = 0
	
	var bs = out_buffer.get_size_x()
	
	var dirt = 1
	
	while z < bs:
		while x < bs:
			
			var c = _image.get_pixel((ox+x) & im_wm, (oz+z) & im_hm)
			var h = int(c.r * 200.0) - 50
			h -= oy
			if h > 0:
				if h > bs:
					h = bs
				out_buffer.fill_area(dirt, Vector3(x,0,z), Vector3(x+1,h,z+1), channel)
			
			x += 1
		z += 1
		x = 0
	
	_image.unlock()


#func emerge_block_noise(out_buffer, origin_in_voxels):
#	var ox = origin_in_voxels.x
#	var oy = origin_in_voxels.y
#	var oz = origin_in_voxels.z
#	var ns1 = 0.01
#	var ns2 = 0.05
#	
#	var dirt = 1
#	#if oy < 0:
#	#	dirt = 2
#	
#	var air = 0
#	#if oy < 0:
#	#	air = 4
#	
#	var bs = voxels.get_size_x()
#	
#	var noise1 = OsnFractalNoise.new()
#	noise1.set_source_noise(_noise)
#	noise1.set_period(150)
#	noise1.set_octaves(5)
#	
#	var noise2 = OsnFractalNoise.new()
#	noise2.set_source_noise(_noise2)
#	noise2.set_period(256)
#	noise2.set_octaves(5)
#	
#	for z in range(0, bs):
#		for x in range(0, bs):
#			
#			#var n2 = noise2.get_noise_2d(ox+x, oz+z)
#			#	n2 = (n2+0.5)*8 - 1
#			#	if n2 > 0.0:
#			#		n2 = 0.0
#			
#			var n1 = noise1.get_noise_2d(ox+x, oz+z)
#			
#			var h = floor(64.0 * n1 - oy)
#			
#			if h >= 0:
#				if h < bs:
#					voxels.fill_area(dirt, Vector3(x,0,z), Vector3(x+1,h,z+1), channel)
#					voxels.fill_area(air, Vector3(x,h,z), Vector3(x+1,bs,z+1), channel)
#				else:
#					voxels.fill_area(dirt, Vector3(x,0,z), Vector3(x+1,bs,z+1), channel)
#			else:
#				voxels.fill_area(air, Vector3(x,0,z), Vector3(x+1,bs,z+1), channel)
