extends Control

signal material_selected(index: int)

@onready var _item_list : ItemList = $MC/HB/PC/VB/ItemList
@onready var _pointed_label : Label = $MC/HB/VB/PC/MC/PointedLabel


func _ready():
	for i in 16:
		_item_list.add_item(str("Texture ", i))


func _on_item_list_item_selected(index: int):
	material_selected.emit(index)


func set_selected_material_index(i: int):
	_item_list.select(i)


func set_pointed_label(text: String):
	_pointed_label.text = text

