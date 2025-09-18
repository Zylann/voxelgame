extends Node

const NETWORK_MODE_SINGLEPLAYER = 0
const NETWORK_MODE_CLIENT = 1
const NETWORK_MODE_HOST = 2

const SERVER_PEER_ID = 1

const CharacterScene = preload("./player/character_avatar.tscn")
const RemoteCharacterScene = preload("./player/remote_character.tscn")
const RandomTicks = preload("./random_ticks.gd")
const WaterUpdater = preload("./water.gd")

@onready var _light : DirectionalLight3D = $DirectionalLight3D
@onready var _terrain : VoxelTerrain = $VoxelTerrain
@onready var _characters_container : Node = $Players

var _network_mode := NETWORK_MODE_SINGLEPLAYER
var _ip := ""
var _port := -1

# Initially needed because when running multiple instances in the editor, Godot is mixing up the
# outputs of server and clients in the same output console...
# 2025/05/01: had to prefix because Godot now has a Logger class
class BG_Logger:
	var prefix := ""
	
	func debug(msg: String):
		print(prefix, msg)

	func error(msg: String):
		push_error(prefix, msg)


var _logger := BG_Logger.new()


func get_terrain() -> VoxelTerrain:
	return _terrain


func get_network_mode() -> int:
	return _network_mode


func set_network_mode(mode: int):
	_network_mode = mode


func set_ip(ip: String):
	_ip = ip


func set_port(port: int):
	_port = port


func _ready():
	if _network_mode == NETWORK_MODE_HOST:
		_logger.prefix = "Server: "
		
		# Configure multiplayer API as server
		var peer := ENetMultiplayerPeer.new()
		var err := peer.create_server(_port, 32, 0, 0, 0)
		if err != OK:
			_logger.error(str("Failed to create server peer, error ", err))
			return
		var mp := get_tree().get_multiplayer()
		mp.peer_connected.connect(_on_peer_connected)
		mp.peer_disconnected.connect(_on_peer_disconnected)
		mp.multiplayer_peer = peer

		# Configure VoxelTerrain as server
		var synchronizer := VoxelTerrainMultiplayerSynchronizer.new()
		_terrain.add_child(synchronizer)

	elif _network_mode == NETWORK_MODE_CLIENT:
		_logger.prefix = "Client: "
		
		# Configure multiplayer API as client
		var peer := ENetMultiplayerPeer.new()
		var err := peer.create_client(_ip, _port, 0, 0, 0, 0)
		if err != OK:
			_logger.error(str("Failed to create client peer, error ", err))
			return
		var mp := get_tree().get_multiplayer()
		mp.connected_to_server.connect(_on_connected_to_server)
		mp.connection_failed.connect(_on_connection_failed)
		mp.peer_connected.connect(_on_peer_connected)
		mp.peer_disconnected.connect(_on_peer_disconnected)
		mp.server_disconnected.connect(_on_server_disconnected)
		mp.multiplayer_peer = peer

		# Configure VoxelTerrain as client
		var synchronizer := VoxelTerrainMultiplayerSynchronizer.new()
		_terrain.add_child(synchronizer)
		_terrain.stream = null

	if _network_mode == NETWORK_MODE_HOST or _network_mode == NETWORK_MODE_SINGLEPLAYER:
		add_child(RandomTicks.new())
		
		var water_updater := WaterUpdater.new()
		# Current code grabs this node by name, so must be named for now...
		water_updater.name = "Water"
		add_child(water_updater)
		
		_spawn_character(SERVER_PEER_ID, Vector3(0, 64, 0))


func _on_connected_to_server():
	_logger.debug("connected to server")


func _on_connection_failed():
	_logger.debug("Connection failed")


func _on_peer_connected(new_peer_id: int):
	_logger.debug(str("peer ", new_peer_id, " connected"))
	
	if _network_mode == NETWORK_MODE_HOST:
		# Spawn own character
		var new_character = _spawn_remote_character(new_peer_id, Vector3(0, 64, 0))
		_logger.debug(str("Sending own character to ", new_peer_id))
		rpc_id(new_peer_id, &"receive_own_character", new_peer_id, new_character.position)
		
		# Send existing characters to the new peer
		for i in _characters_container.get_child_count():
			var character := _characters_container.get_child(i)
			if character != new_character:
				# TODO This sucks, find a better way to get peer ID from character
				var peer_id := character.name.to_int()
				_logger.debug(str("Sending remote character ", peer_id, " to ", new_peer_id))
				rpc_id(new_peer_id, &"receive_remote_character", peer_id, character.position)
		
		# Send new character to other clients
		var peers := get_tree().get_multiplayer().get_peers()
		for peer_id in peers:
			if peer_id != new_peer_id:
				_logger.debug(str("Sending remote character ", peer_id, " to other ", new_peer_id))
				rpc_id(peer_id, &"receive_remote_character", new_peer_id, new_character.position)


func _on_peer_disconnected(peer_id: int):
	_logger.debug(str("Peer ", peer_id, " disconnected"))
	# Remove character
	var node_name = str(peer_id)
	if _characters_container.has_node(node_name):
		var character = _characters_container.get_node(node_name)
		character.queue_free()
	else:
		_logger.debug(str("Character ", peer_id, " not found"))


func _on_server_disconnected():
	_logger.debug("Server disconnected")
	# TODO Go back to main menu, the game will spam RPC errors


func _unhandled_input(event: InputEvent):
	# TODO Make a pause menu with options?
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_L:
				# Toggle shadows
				_light.shadow_enabled = not _light.shadow_enabled
#			if event.keycode == KEY_KP_0:
#				# Force save
#				_save_world()


func _notification(what: int):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			if _network_mode == NETWORK_MODE_HOST or _network_mode == NETWORK_MODE_SINGLEPLAYER:
				# Save game when the user closes the window
				_save_world()


func _save_world():
	_terrain.save_modified_blocks()


func _spawn_character(peer_id: int, pos: Vector3) -> Node3D:
	var node_name = str(peer_id)
	if _characters_container.has_node(node_name):
		_logger.error(str("Character ", peer_id, " already created"))
		return null
	var character : Node3D = CharacterScene.instantiate()
	character.name = node_name
	character.position = pos
	character.terrain = get_terrain().get_path()
	_characters_container.add_child(character)
	return character


func _spawn_remote_character(peer_id: int, pos: Vector3) -> Node3D:
	var node_name = str(peer_id)
	if _characters_container.has_node(node_name):
		_logger.debug(str("Remote character ", peer_id, " already created"))
		return null
	var character := RemoteCharacterScene.instantiate()
	character.position = pos
	character.name = str(peer_id)
	if _network_mode == NETWORK_MODE_HOST:
		# The server is authoritative on voxel terrain, so it needs a viewer to load terrain
		# around each character. We'll also tell which peer ID it uses, so the terrain knows which
		# peer to send the voxels to.
		# TODO Make a specific scene?
		var viewer := VoxelViewer.new()
		viewer.view_distance = 128
		viewer.requires_visuals = false
		viewer.requires_collisions = false
		viewer.set_network_peer_id(peer_id)
		viewer.set_requires_data_block_notifications(true)
		#viewer.requires_data_block_notifications = true
		character.add_child(viewer)
	_characters_container.add_child(character)
	return character


@rpc("authority", "call_remote", "reliable", 0)
func receive_remote_character(peer_id: int, pos: Vector3):
	_logger.debug(str("receive_remote_character ", peer_id, " at ", pos))
	_spawn_remote_character(peer_id, pos)


@rpc("authority", "call_remote", "reliable", 0)
func receive_own_character(peer_id: int, pos: Vector3):
	_logger.debug(str("receive_own_character ", peer_id, " at ", pos))
	_spawn_character(peer_id, pos)
