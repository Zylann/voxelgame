extends Node

# Note: can't import `Blocks` here, otherwise it's a cylcic ref...
# And I don't want to pollute global space of all the demos with this

# Info packed into a class,
# to not pollute namespace of all the block scripts that could inherit from it
class BaseInfo:
	var id := 0
	var name := ""
	var gui_model_path := ""
	var directory := ""
	var rotation_type := 0
	var sprite_texture : Texture2D
	var transparent := false
	var backface_culling := true
	# TODO Rename `variants`
	var voxels := PackedInt32Array()


var base_info := BaseInfo.new()


func place(_voxel_tool: VoxelTool, _pos: Vector3, _look_dir: Vector3):
	pass
