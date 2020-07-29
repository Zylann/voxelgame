extends CenterContainer

const Blocks = preload("../blocks/blocks.tres")

onready var _selected_frame = $HBoxContainer/HotbarSlot/HotbarSlotSelect
onready var _slot_container = $HBoxContainer

var _inventory = [1, 2, 3, 4, 5, 6, 7, -1, -1]
var _inventory_index = 0


func _ready():
	assert(len(_inventory) == _slot_container.get_child_count())
	for i in len(_inventory):
		var block_id = _inventory[i]
		var slot = _slot_container.get_child(i)
		slot.set_block_id(block_id)


func select_slot(i: int):
	if _inventory_index == i:
		return
	assert(i >= 0 and i < len(_inventory))
	_inventory_index = i
	
	var block_id = _inventory[_inventory_index]
	if block_id != -1:
		var block = Blocks.get_block(block_id)
		print("Inventory select ", block.name)
	
	_selected_frame.get_parent().remove_child(_selected_frame)
	var slot = _slot_container.get_child(i)
	slot.add_child(_selected_frame)


func get_selected_block_type() -> int:
	return _inventory[_inventory_index]


func try_select_slot_by_block_id(block_id: int):
	for i in len(_inventory):
		var id = _inventory[i]
		if id == block_id:
			select_slot(i)
			break


func select_next_slot():
	var i = _inventory_index + 1
	if i >= len(_inventory):
		i = 0
	select_slot(i)


func select_previous_slot():
	var i = _inventory_index - 1
	if i < 0:
		i = len(_inventory) - 1
	select_slot(i)


