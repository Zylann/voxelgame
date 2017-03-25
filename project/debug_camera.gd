
# Generic debug camera controller. Use anywhere.
# Nothing game-related, no reference from and to outside.

extends Camera


export var sensitivity = 0.4
export var min_angle = -90
export var max_angle = 90
export var speed = 10.0
export var capture_mouse = true

var _yaw = 0
var _pitch = 0
var _forward = Vector3(0,0,0)
var _current_speed = 0
var _max_speed = 0


func _ready():
	if capture_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_process(true)
	set_process_input(true)
	_current_speed = speed
	_max_speed = speed * 10


func get_forward():
	return get_transform().basis * Vector3(0,0,-1)


func _process(delta):
	var motor = Vector3(0,0,0)
	
	var forward = get_forward()
	var right = get_transform().basis * Vector3(1,0,0)
	var up = Vector3(0,1,0)
	
	if abs(forward.y) < 1.0:
		_forward = Vector3(forward.x, 0, forward.z).normalized()
	
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W):
		motor += _forward
	if Input.is_key_pressed(KEY_S):
		motor -= _forward
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A):
		motor -= right
	if Input.is_key_pressed(KEY_D):
		motor += right
	if Input.is_key_pressed(KEY_SPACE):
		motor += up
	if Input.is_key_pressed(KEY_SHIFT):
		motor -= up
	
	set_translation(get_translation() + motor * (delta * _current_speed))
	
	if motor.length_squared() > 0:
		_current_speed *= 1.02
		if _current_speed > _max_speed:
			_current_speed = _max_speed
	else:
		_current_speed = speed


func _input(event):
	if event.type == InputEvent.MOUSE_BUTTON:
		if event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			if capture_mouse:
				# Capture the mouse
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	elif event.type == InputEvent.MOUSE_MOTION:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED || not capture_mouse:
			# Get mouse delta
			var motion = event.relative_pos
			
			# Add to rotations
			_yaw -= motion.x * sensitivity
			_pitch += motion.y * sensitivity
			
			# Clamp pitch
			var e = 0.001
			if _pitch > max_angle-e:
				_pitch = max_angle-e
			elif _pitch < min_angle+e:
				_pitch = min_angle+e
			
			# Apply rotations
			set_rotation(Vector3(0, deg2rad(_yaw), 0))
			rotate(get_transform().basis.x.normalized(), -deg2rad(_pitch))
	
	elif event.type == InputEvent.KEY:
		if event.pressed:
			if event.scancode == KEY_ESCAPE:
				# Get the mouse back
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			elif event.scancode == KEY_I:
				var pos = get_translation()
				var fw = get_forward()
				print("Position: ", pos, ", Forward: ", fw)
