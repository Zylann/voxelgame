extends Control


onready var _texture_rect = $TextureRect
onready var _block_types = get_node("/root/Main/Blocks")


func set_block_id(id: int):
	if id == -1:
		_texture_rect.texture = null
	else:
		var block = _block_types.get_block(id)
		_texture_rect.texture = block.base_info.sprite_texture

