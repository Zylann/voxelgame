extends Node3D


@rpc("any_peer", "call_remote", "unreliable", 0)
func receive_position(pos: Vector3):
	position = pos

