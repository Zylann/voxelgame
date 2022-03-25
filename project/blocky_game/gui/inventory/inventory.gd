extends Control

signal changed

const BAG_WIDTH = 9
const BAG_HEIGHT = 3
const HOTBAR_HEIGHT = 1

const InventoryItem = preload("../../player/inventory_item.gd")

@onready var _bag_container = $CC/PC/VB/Bag
@onready var _hotbar_container = $CC/PC/VB/Hotbar
@onready var _dragged_item_view = $DraggedItem

# TODO Is it worth having the hotbar in the first indexes instead of the last ones?
var _slots := []
var _slot_views := []
var _previous_mouse_mode := 0
var _dragged_slot := -1


func _ready():
	_slots.resize(BAG_WIDTH * (BAG_HEIGHT + HOTBAR_HEIGHT))
	assert(_bag_container.get_child_count() == BAG_WIDTH * BAG_HEIGHT)
	assert(_hotbar_container.get_child_count() == BAG_WIDTH * HOTBAR_HEIGHT)
	
	# Initial contents
	var hotbar_begin_index := BAG_WIDTH * BAG_HEIGHT
	_slots[hotbar_begin_index + 0] = _make_item(InventoryItem.TYPE_BLOCK, 1)
	_slots[hotbar_begin_index + 1] = _make_item(InventoryItem.TYPE_BLOCK, 2)
	_slots[hotbar_begin_index + 2] = _make_item(InventoryItem.TYPE_BLOCK, 3)
	_slots[hotbar_begin_index + 3] = _make_item(InventoryItem.TYPE_BLOCK, 4)
	_slots[hotbar_begin_index + 4] = _make_item(InventoryItem.TYPE_BLOCK, 5)
	_slots[hotbar_begin_index + 5] = _make_item(InventoryItem.TYPE_BLOCK, 6)
	_slots[hotbar_begin_index + 6] = _make_item(InventoryItem.TYPE_BLOCK, 7)
	_slots[hotbar_begin_index + 7] = _make_item(InventoryItem.TYPE_ITEM, 0)
	_slots[hotbar_begin_index + 8] = _make_item(InventoryItem.TYPE_BLOCK, 9)
	_slots[0] = _make_item(InventoryItem.TYPE_BLOCK, 8)

	# Init views
	var slot_idx := 0
	_slot_views.resize(len(_slots))
	for container in [_bag_container, _hotbar_container]:
		for i in container.get_child_count():
			var slot = container.get_child(i)
			slot.get_display().set_item(_slots[slot_idx])
			slot.pressed.connect(_on_slot_pressed.bind(slot_idx))
			_slot_views[slot_idx] = slot
			slot_idx += 1


static func _make_item(type, id):
	var i = InventoryItem.new()
	i.id = id
	i.type = type
	return i


func _update_views():
	var slot_idx := 0
	for container in [_bag_container, _hotbar_container]:
		for i in container.get_child_count():
			var slot = container.get_child(i)
			slot.get_display().set_item(_slots[slot_idx])
			slot_idx += 1


func get_hotbar_slot_count() -> int:
	return BAG_WIDTH


func get_hotbar_slot_data(i) -> InventoryItem:
	var hotbar_begin_index := BAG_WIDTH * BAG_HEIGHT
	return _slots[hotbar_begin_index + i]


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_E:
				visible = not visible
			elif visible and event.keycode == KEY_ESCAPE:
				visible = false
				get_viewport().set_input_as_handled()


func _notification(what: int):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not is_inside_tree():
			print("Visibility changed while not in tree? Eh?")
			return

		if visible:
			_update_views()
			
			_previous_mouse_mode = Input.get_mouse_mode()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
		else:
			if _dragged_slot != -1:
				# Cancel drag
				_slot_views[_dragged_slot].get_display().set_item(_slots[_dragged_slot])
				_dragged_item_view.stop()
			_dragged_slot = -1
			_dragged_item_view.stop()
			
			Input.set_mouse_mode(_previous_mouse_mode)


func _on_slot_pressed(idx: int):
	if _dragged_slot == -1:
		if _slots[idx] == null:
			return
		# Start drag
		_dragged_slot = idx
		_slot_views[_dragged_slot].get_display().set_item(null)
		_dragged_item_view.start(_slots[idx])
	
	else:
		if _slots[idx] == null:
			# Move
			_slots[idx] = _slots[_dragged_slot]
			_slots[_dragged_slot] = null
			_slot_views[idx].get_display().set_item(_slots[idx])
			_dragged_item_view.stop()
			_dragged_slot = -1
			emit_signal("changed")
		
		else:
			if _dragged_slot != idx:
				# Swap
				var tmp = _slots[idx]
				_slots[idx] = _slots[_dragged_slot]
				_slots[_dragged_slot] = tmp
				_dragged_item_view.start(tmp)

			else:
				_dragged_slot = -1
				_dragged_item_view.stop()

			_slot_views[idx].get_display().set_item(_slots[idx])

			emit_signal("changed")
