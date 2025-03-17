extends Node


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_B:
				spawn()


func spawn():
	var body = RigidBody3D.new()
	var collision_shape = CollisionShape3D.new()
	var cube_shape = BoxShape3D.new()
	collision_shape.shape = cube_shape
	body.add_child(collision_shape)
	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)
	body.transform = get_parent().transform
	var camera := get_viewport().get_camera_3d()
	body.linear_velocity = -10.0 * camera.global_transform.basis.z
	var parent := get_parent().get_parent()
	print(parent)
	parent.add_child(body)
