extends "../item.gd"

const RocketScene = preload("./rocket.tscn")

onready var _world = get_node("/root/Main")


func use(trans: Transform):
	var rocket = RocketScene.instance()
	rocket.translation = trans.origin
	_world.add_child(rocket)
	print("Launch rocket at ", rocket.translation)
	var forward = -trans.basis.z.normalized()
	rocket.set_direction(forward)

