extends Control

const Blocks = preload("../../blocks/blocks.tres")


onready var _texture_rect = $TextureRect


func set_block_id(id: int):
	if id == -1:
		_texture_rect.texture = null
	else:
		var block = Blocks.get_block(id)
		_texture_rect.texture = block.sprite_texture

