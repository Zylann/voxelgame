extends Node3D

const Util = preload("res://common/util.gd")

@export var sensitivity = 0.4
@export var min_angle = -90
@export var max_angle = 90
@export var capture_mouse = true
@export var distance = 0.0

var _yaw = 0
var _pitch = 0
var _offset = Vector3()


func _ready():
	_offset = position
	if capture_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.pressed and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			if capture_mouse:
				# Capture the mouse
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
		# The game uses the wheel already, put that "debug" adjustment behind a modifier
		if event.ctrl_pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				distance = max(distance - 1 - distance * 0.1, 0.0)
				update_rotations()
			
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				distance = max(distance + 1 + distance * 0.1, 0.0)
				update_rotations()
	
	elif event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED || not capture_mouse:
			# Get mouse delta
			var motion = event.relative
			
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
			update_rotations()
	
	elif event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_ESCAPE:
				# Get the mouse back
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
			elif event.keycode == KEY_I:
				var pos = position
				var fw = -transform.basis.z
				print("Position: ", pos, ", Forward: ", fw)


func update_rotations():
	set_position(Vector3())
	set_rotation(Vector3(0, deg_to_rad(_yaw), 0))
	rotate(get_transform().basis.x.normalized(), -deg_to_rad(_pitch))
	set_position(get_transform().basis.z * distance + _offset)
