extends Control

@onready var _ip_line_edit : LineEdit = \
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/IP
@onready var _port_spinbox : SpinBox = \
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Port

signal singleplayer_requested()
signal connect_to_server_requested(ip, port)
signal host_server_requested(port)
signal upnp_toggled(pressed)


func _on_singleplayer_button_pressed():
	singleplayer_requested.emit()


func _on_connect_to_server_button_pressed():
	var ip := _ip_line_edit.text.strip_edges()
	if ip == "":
		return
	# TODO Do more validation on the syntax of IP address
	var port : int = _port_spinbox.value
	connect_to_server_requested.emit(ip, port)


func _on_host_server_button_pressed():
	var port : int = _port_spinbox.value
	host_server_requested.emit(port)


func _on_upnp_checkbox_toggled(button_pressed: bool):
	upnp_toggled.emit(button_pressed)
