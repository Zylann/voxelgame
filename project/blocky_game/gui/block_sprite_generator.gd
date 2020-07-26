extends Node

const Blocks = preload("../blocks/blocks.gd")
const BlocksAtlasTexture = preload("../blocks/terrain.png")

onready var _viewport : Viewport = $Viewport
onready var _mesh_instance : MeshInstance = $Viewport/MeshInstance

var _current_block_id := -1
var _blocks := Blocks.new()


func _process(_delta):
	print("Block ", _current_block_id)

	if _current_block_id != -1:
		var block : Blocks.Block = _blocks.get_block(_current_block_id)
		if block.directory != "":
			# Grab result of previous render
			var viewport_texture := _viewport.get_texture()
			var im := viewport_texture.get_data()
			im.convert(Image.FORMAT_RGBA8)
			var fpath := \
				str(Blocks.ROOT, "/", block.directory, "/", block.name, "_sprite.png")
			var err = im.save_png(fpath)
			if err != OK:
				push_error(str("Could not save ", fpath, ", error ", err))
			else:
				print("Saved ", fpath)

	_current_block_id += 1

	if _current_block_id < _blocks.get_block_count():
		# Setup next block for rendering
		var block = _blocks.get_block(_current_block_id)
		if block.directory != "":
			var gui_mesh = load(block.gui_model_path)
			_mesh_instance.mesh = gui_mesh
			var mat = SpatialMaterial.new()
			mat.albedo_texture = BlocksAtlasTexture
			_mesh_instance.material_override = mat
			if block.transparent:
				mat.params_use_alpha_scissor = true
			if not block.backface_culling:
				mat.params_cull_mode = SpatialMaterial.CULL_DISABLED

	else:
		set_process(false)
		print("Done!")

