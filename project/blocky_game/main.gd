extends Node

const BlockyGame = preload("./blocky_game.gd")
const BlockyGameScene = preload("./blocky_game.tscn")

const MainMenu = preload("./main_menu.gd")

@onready var _main_menu : MainMenu = $MainMenu

var _game : BlockyGame


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
	_game = BlockyGameScene.instantiate()
	_game.set_port(port)
	_game.set_network_mode(BlockyGame.NETWORK_MODE_HOST)
	add_child(_game)

	_main_menu.hide()

	get_viewport().get_window().title = "Server"
