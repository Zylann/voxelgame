extends Node

const BlockyGame = preload("./blocky_game.gd")
const BlockyGameScene = preload("./blocky_game.tscn")
const MainMenu = preload("./main_menu.gd")
const UPNPHelper = preload("./upnp_helper.gd")

@onready var _main_menu : MainMenu = $MainMenu

var _game : BlockyGame
var _upnp_helper : UPNPHelper


func _on_main_menu_singleplayer_requested():
	_game = BlockyGameScene.instantiate()
	_game.set_network_mode(BlockyGame.NETWORK_MODE_SINGLEPLAYER)
	add_child(_game)
	
	_main_menu.hide()


func _on_main_menu_connect_to_server_requested(ip: String, port: int):
	_game = BlockyGameScene.instantiate()
	_game.set_ip(ip)
	_game.set_port(port)
	_game.set_network_mode(BlockyGame.NETWORK_MODE_CLIENT)
	add_child(_game)

	_main_menu.hide()

	get_viewport().get_window().title = "Client"


func _on_main_menu_host_server_requested(port: int):
	if _upnp_helper != null and not _upnp_helper.is_setup():
		_upnp_helper.setup(port, PackedStringArray(["UDP"]), "VoxelBlockyGame", 20 * 60)
	
	_game = BlockyGameScene.instantiate()
	_game.set_port(port)
	_game.set_network_mode(BlockyGame.NETWORK_MODE_HOST)
	add_child(_game)

	_main_menu.hide()

	get_viewport().get_window().title = "Server"


func _on_main_menu_upnp_toggled(pressed: bool):
	if pressed:
		if _upnp_helper == null:
			_upnp_helper = UPNPHelper.new()
			add_child(_upnp_helper)
	else:
		if _upnp_helper != null:
			_upnp_helper.queue_free()
			_upnp_helper = null
