extends Control

signal pressed

const InventoryItemDisplay = preload("../inventory_item_display.gd")

@onready var _select_bg = $SelectBG
@onready var _display = $TextureRect


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			emit_signal("pressed")


func _notification(what: int):
	match what:
		NOTIFICATION_MOUSE_ENTER:
			_select_bg.visible = true
		
		NOTIFICATION_MOUSE_EXIT:
			_select_bg.visible = false

		NOTIFICATION_VISIBILITY_CHANGED:
			if not is_visible_in_tree():
				_select_bg.visible = false


func get_display() -> InventoryItemDisplay:
	return _display

