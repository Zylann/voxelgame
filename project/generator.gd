
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
	func generate(voxels, offset):
		var ox = offset.x
		var oy = offset.y
		var oz = offset.z
		var empty = true
		var ns1 = 0.01
		var ns2 = 0.05
		
		var dirt = 1
		if oy < 0:
			dirt = 2
		
		var bs = voxels.get_size_x()
		
		var noise1 = OsnFractalNoise.new()
		noise1.set_source_noise(_noise)
		noise1.set_period(128)
		noise1.set_octaves(4)
		
		for z in range(0, bs):
			for x in range(0, bs):
				
				var h = 16.0 * noise1.get_noise_2d(ox+x, oz+z) - oy
				
				if h >= 0:
					if h < bs:
						empty = false
						for y in range(0, h):
							voxels.set_voxel(dirt, x,y,z)
							#voxels[z][y][x] = dirt
						for y in range(h, bs):
							voxels.set_voxel(0, x,y,z)
							#voxels[z][y][x] = air
	#					if oy == -BLOCK_SIZE:
	#						voxels[z][bs-1][x] = 0
	#					if oy >= 0 and randf() < 0.2:
	#						voxels[z][h][x] = 2
	#					if randf() < 0.01:
	#						var th = h+1+randi()%8
	#						if th > bs:
	#							th = bs
	#						for y in range(h, th):
	#							voxels[z][y][x] = 3
					else:
						empty = false
						for y in range(0, bs):
							voxels.set_voxel(dirt, x,y,z)
				else:
					for y in range(0, bs):
						voxels.set_voxel(0, x,y,z)

		return empty


class Volume extends _Base:
	func generate(voxels, offset):
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
					if h < 1-gy*0.01 - 1:
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

