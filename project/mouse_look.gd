
extends Spatial

export var sensitivity = 0.4
export var min_angle = -90
export var max_angle = 90
export var capture_mouse = true

var _yaw = 0
var _pitch = 0


func _ready():
	if capture_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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




