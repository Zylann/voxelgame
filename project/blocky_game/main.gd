extends Node

const BlockyGame = preload("./blocky_game.gd")
const BlockyGameScene = preload("./blocky_game.tscn")

const CharacterScene = preload("./player/character_avatar.tscn")

const MainMenu = preload("./main_menu.gd")

@onready var _main_menu : MainMenu = $MainMenu

var _game : BlockyGame


func _on_main_menu_singleplayer_requested():
	_game = BlockyGameScene.instantiate()
	add_child(_game)
	
	var character : Node3D = CharacterScene.instantiate()
	character.position = Vector3(0, 64, 0)
	character.terrain = _game.get_terrain().get_path()
	_game.add_character(character)
	
	_main_menu.hide()


func _on_main_menu_connect_to_server_requested(ip: String, port: int):
	# TODO
	pass # Replace with function body.


func _on_main_menu_host_server_requested(port: int):
	# TODO
	pass # Replace with function body.

