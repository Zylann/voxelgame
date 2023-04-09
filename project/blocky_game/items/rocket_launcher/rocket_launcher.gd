extends "../item.gd"

const Rocket = preload("./rocket.gd")
const RocketScene = preload("./rocket.tscn")

const SERVER_PEER_ID = 1

@onready var _world : Node = get_node("/root/Main/Game")

var _next_rocket_id := 1


func use(trans: Transform3D):
	var mp := get_tree().get_multiplayer()
	if mp.has_multiplayer_peer() and not mp.is_server():
		rpc_id(SERVER_PEER_ID, &"receive_use", trans)
	else:
		_use(trans)


# Only the server may call this
func _use(trans: Transform3D):
	_spawn_rocket(_next_rocket_id, trans.origin, -trans.basis.z.normalized())
	_next_rocket_id += 1


func _spawn_rocket(id: int, pos: Vector3, dir: Vector3):
	var rocket : Rocket = RocketScene.instantiate()
	rocket.position = pos
	# Name must match on client and server
	rocket.name = str("Rocket", id)
	_world.add_child(rocket)
	print("Launch rocket at ", rocket.position)
	rocket.set_direction(dir)
	
	var mp := get_tree().get_multiplayer()
	if mp.has_multiplayer_peer() and mp.is_server():
		# Send rocket to clients
		rpc(&"receive_spawn_rocket", id, pos, dir)


@rpc("any_peer", "call_remote", "reliable", 0)
func receive_use(trans: Transform3D):
	_use(trans)


@rpc("authority", "call_remote", "reliable", 0)
func receive_spawn_rocket(id: int, position: Vector3, direction: Vector3):
	# Get round-trip time so we can compensate for network delay.
	var mp := get_tree().get_multiplayer()
	var peer_id := mp.get_remote_sender_id()
	var mp_peer : ENetMultiplayerPeer = mp.multiplayer_peer
	var peer := mp_peer.get_peer(peer_id)
	var rtt_seconds := peer.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME) / 1000.0
	
	_spawn_rocket(id, position + (rtt_seconds / 2.0) * direction, direction)

	# We could also play some effects when shooting so the player can have immediate feedback,
	# and would help hiding the fact the rocket is spawning a bit late?

