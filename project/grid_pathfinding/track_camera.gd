extends Camera3D


var _yaw := 0.0
var _pitch := 0.0
var _distance := 32.0
var _target := Vector3()
var _rotation_speed := 0.01
var _panning_speed := 0.1


func set_target(v: Vector3):
	_target = v
	_update_camera_transform()


func _input(event):
	if event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE) != 0:

			if Input.is_key_pressed(KEY_SHIFT):
				var trans_basis := global_transform.basis
				_target -= _panning_speed * trans_basis.x * event.relative.x
				_target += _panning_speed * trans_basis.y * event.relative.y
			
			else:
				_yaw -= _rotation_speed * event.relative.x
				_pitch -= _rotation_speed * event.relative.y
			
			_update_camera_transform()
	
	elif event is InputEventMouseButton:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_WHEEL_DOWN:
					_distance *= 1.1
					_update_camera_transform()
				MOUSE_BUTTON_WHEEL_UP:
					_distance /= 1.1
					_update_camera_transform()


func _update_camera_transform():
	var trans_basis := Basis() \
		.rotated(Vector3(1, 0, 0), _pitch) \
		.rotated(Vector3(0, 1, 0), _yaw)
	global_transform = \
		Transform3D(trans_basis, _target + _distance * trans_basis.z)
