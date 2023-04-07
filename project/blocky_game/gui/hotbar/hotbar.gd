extends CenterContainer

const InventoryItem = preload("../../player/inventory_item.gd")

@onready var _selected_frame = $HBoxContainer/HotbarSlot/HotbarSlotSelect
@onready var _slot_container = $HBoxContainer
@onready var _block_types = get_node(^"/root/Main/Game/Blocks")
@onready var _inventory = get_node(^"../Inventory")

var _hotbar_index := 0


func _ready():
	call_deferred("_update_views")


func _update_views():
	for i in _inventory.get_hotbar_slot_count():
		var slot_data = _inventory.get_hotbar_slot_data(i)
		var slot_view = _slot_container.get_child(i)
		slot_view.get_display().set_item(slot_data)


func select_slot(i: int):
	if _hotbar_index == i:
		return
	assert(i >= 0 and i < _inventory.get_hotbar_slot_count())
	_hotbar_index = i
	
	var item = _inventory.get_hotbar_slot_data(_hotbar_index)
	if item != null:
		if item.type == InventoryItem.TYPE_BLOCK:
			var block = _block_types.get_block(item.id)
			print("Hotbar select block ", block.base_info.name)
			
		elif item.type == InventoryItem.TYPE_ITEM:
			# TODO Item db
			print("Hotbar select item ", item.id)
	
	_selected_frame.get_parent().remove_child(_selected_frame)
	var slot = _slot_container.get_child(i)
	slot.add_child(_selected_frame)


func get_selected_item() -> InventoryItem:
	return _inventory.get_hotbar_slot_data(_hotbar_index)


func try_select_slot_by_block_id(block_id: int):
	for i in _inventory.get_hotbar_slot_count():
		var item = _inventory.get_hotbar_slot_data(i)
		if item.type == InventoryItem.TYPE_BLOCK:
			if item.id == block_id:
				select_slot(i)
				break


func select_next_slot():
	var i = _hotbar_index + 1
	if i >= _inventory.get_hotbar_slot_count():
		i = 0
	select_slot(i)


func select_previous_slot():
	var i = _hotbar_index - 1
	if i < 0:
		i = _inventory.get_hotbar_slot_count() - 1
	select_slot(i)


func _on_Inventory_changed():
	_update_views()
