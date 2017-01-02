extends VoxelProvider

const Generators = preload("generator.gd")

var _generator = null


func _init():
	_generator = Generators.Volume.new()


func emerge_block(out_buffer, block_pos):
	_generator.generate(out_buffer, block_pos)


#func immerge_block(buffer, bock_pos):
#	pass
