extends Node

const Blocks = preload("../blocks/blocks.gd")
const Block = Blocks.Block

#const _materials : Array[Material] = [
	#preload("res://blocky_game/blocks/terrain_material.tres"),
	#preload("res://blocky_game/blocks/terrain_material_transparent.tres"),
	#preload("res://blocky_game/blocks/terrain_material_foliage.tres")
#]

@onready var _viewport : SubViewport = $SubViewport
@onready var _mesh_instance : MeshInstance3D = $SubViewport/MeshInstance3D

var _current_block_id := -1
var _blocks := Blocks.new()


func _ready():
	add_child(_blocks)


func _process(_delta):
	print("Block ", _current_block_id)

	if _current_block_id != -1:
		var block : Block.BaseInfo = _blocks.get_block(_current_block_id).base_info
		if block.directory != "":
			# Grab result of previous render
			var viewport_texture := _viewport.get_texture()
			var im := viewport_texture.get_image()
			im.convert(Image.FORMAT_RGBA8)
			var fpath := \
				str(Blocks.ROOT, "/", block.directory, "/", block.name, "_sprite.png")
			var err := im.save_png(fpath)
			if err != OK:
				push_error(str("Could not save ", fpath, ", error ", err))
			else:
				print("Saved ", fpath)

	_current_block_id += 1

	if _current_block_id < _blocks.get_block_count():
		# Setup next block for rendering
		var block : Block.BaseInfo = _blocks.get_block(_current_block_id).base_info
		if block.directory != "":
			var gui_mesh : Mesh = load(block.gui_model_path)
			_mesh_instance.mesh = gui_mesh
			var lib := _blocks.get_model_library()
			var model := lib.get_model(block.voxels[0])
			var mat := model.get_material_override(0)
			_mesh_instance.material_override = mat

	else:
		set_process(false)
		print("Done!")
