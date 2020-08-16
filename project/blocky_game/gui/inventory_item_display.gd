extends TextureRect

const InventoryItem = preload("res://blocky_game/player/inventory_item.gd")
const DefaultTexture = preload("res://icon.png")
const Blocks = preload("../blocks/blocks.gd")

onready var _block_types : Blocks = get_node("/root/Main/Blocks")


func set_item(data: InventoryItem):
	if data == null:
		texture = null
		
	elif data.type == InventoryItem.TYPE_BLOCK:
		var block := _block_types.get_block(data.id)
		texture = block.base_info.sprite_texture

	elif data.type == InventoryItem.TYPE_ITEM:
		# TODO Items db
		texture = DefaultTexture
	
	else:
		assert(false)
