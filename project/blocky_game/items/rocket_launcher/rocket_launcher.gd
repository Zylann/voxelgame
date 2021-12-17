extends "../item.gd"

const RocketScene = preload("./rocket.tscn")

@onready var _world = get_node("/root/Main")


func use(trans: Transform3D):
	var rocket = RocketScene.instantiate()
	rocket.position = trans.origin
	_world.add_child(rocket)
	print("Launch rocket at ", rocket.position)
	var forward = -trans.basis.z.normalized()
	rocket.set_direction(forward)

