
class _Base:
	var _noise = OsnNoise.new()
	func _init():
		_noise.set_seed(131183)


class Flat extends _Base:
	func generate(voxels, offset):
		if offset.y <= 0:
			voxels.fill(1)

class Grid extends _Base:
	var step = 4
	
	func generate(voxels, offset):

		for z in range(0, voxels.get_size_z()):
			for x in range(0, voxels.get_size_x()):
				for y in range(0, voxels.get_size_y()):
					
					var v = 0
					
					if (y/step)%2 == 0:
						if (x/step)%2 == 0:
							if (z/step)%2 == 0:
								v = 1
						else:
							if (z/step)%2 != 0:
								v = 1
					else:
						if (x/step)%2 == 0:
							if (z/step)%2 != 0:
								v = 1
						else:
							if (z/step)%2 == 0:
								v = 1
					
					voxels.set_voxel(v, x,y,z)


class Heightmap extends _Base:
	var _noise2 = OsnNoise.new()
	
	func _init():
		_noise2.set_seed(_noise.get_seed() + 1)
	
	func generate(voxels, offset):
		offset *= 16
		var ox = offset.x
		var oy = offset.y
		var oz = offset.z
		var ns1 = 0.01
		var ns2 = 0.05
		
		var dirt = 1
		if oy < 0:
			dirt = 2
			
		var air = 0
		if oy < 0:
			air = 4
		
		var bs = voxels.get_size_x()
		
		var noise1 = OsnFractalNoise.new()
		noise1.set_source_noise(_noise)
		noise1.set_period(150)
		noise1.set_octaves(5)
		
		var noise2 = OsnFractalNoise.new()
		noise2.set_source_noise(_noise2)
		noise2.set_period(256)
		noise2.set_octaves(5)
		
		for z in range(0, bs):
			for x in range(0, bs):
				
				#var n2 = noise2.get_noise_2d(ox+x, oz+z)
#				n2 = (n2+0.5)*8 - 1
#				if n2 > 0.0:
#					n2 = 0.0
				
				var n1 = noise1.get_noise_2d(ox+x, oz+z)
				
				var h = floor(64.0 * n1 - oy)
				
				if h >= 0:
					if h < bs:
						voxels.fill_area(dirt, Vector3(x,0,z), Vector3(x+1,h,z+1))
						voxels.fill_area(air, Vector3(x,h,z), Vector3(x+1,bs,z+1))
					else:
						voxels.fill_area(dirt, Vector3(x,0,z), Vector3(x+1,bs,z+1))
				else:
					voxels.fill_area(air, Vector3(x,0,z), Vector3(x+1,bs,z+1))


class Volume extends _Base:
	func generate(voxels, offset):
		offset *= 16
		var ox = offset.x
		var oy = offset.y
		var oz = offset.z
		var empty = true
		var bs = voxels.get_size_x()
		
		var noise1 = OsnFractalNoise.new()
		noise1.set_source_noise(_noise)
		noise1.set_period(100)
		noise1.set_octaves(4)
		
		var dirt = 1
		if oy < 0:
			dirt = 2
	
		for z in range(0, bs):
			for x in range(0, bs):
				for y in range(0, bs):
					var gy = y+oy
					var h = noise1.get_noise_3d(x+ox+2, gy, z+oz)
					if h < 1-gy*0.005 - 1:
						voxels.set_voxel(dirt, x, y, z)
						empty = false
					else:
						if gy < 0:
							voxels.set_voxel(4, x, y, z)
						else:
							voxels.set_voxel(0, x, y, z)
							empty = false
		
		return empty


class Test extends _Base:
	func generate(voxels, offset):
		voxels.set_voxel(1, 1,1,1)
		
		voxels.set_voxel(1, 3,1,1)
		voxels.set_voxel(1, 3,1,2)
		
		voxels.set_voxel(1, 5,1,1)
		voxels.set_voxel(1, 5,1,2)
		voxels.set_voxel(1, 5,2,1)
	
		voxels.set_voxel(1, 8,1,1)
		voxels.set_voxel(1, 8,2,1)
		voxels.set_voxel(1, 7,1,1)
	
		voxels.set_voxel(1, 11,1,1)
		voxels.set_voxel(1, 11,2,1)
		voxels.set_voxel(1, 10,1,1)
		voxels.set_voxel(1, 10,1,2)
		
		for x in range(4,7):
			for z in range(4,7):
				voxels.set_voxel(1, x, 2, z)
				voxels.set_voxel(1, x+5, 2, z)
		voxels.set_voxel(1, 5,3,5)
		voxels.set_voxel(1, 5,1,5)
		
		return false

