extends Spatial

export var speed = 5.0
export var gravity = 9.8
export var jump_force = 5.0
export(NodePath) var head = null

# Not used in this script, but might be useful for child nodes because
# this controller will most likely be on the root
export(NodePath) var terrain = null

var _velocity = Vector3()
var _grounded = false
var _head = null
var _box_mover = VoxelBoxMover.new()


func _ready():
	_head = get_node(head)
	
	# FIX
	#set_shape_transform(0, Transform().rotated(Vector3(1,0,0), PI/2.0))


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.scancode == KEY_1:
				var light = get_node("../DirectionalLight")
				light.shadow_enabled = not light.shadow_enabled
				
			elif event.scancode == KEY_2:
				OS.set_use_vsync(not OS.is_vsync_enabled())
				print("Vsync: ", OS.is_vsync_enabled())


func _physics_process(delta):
	
	var forward = _head.get_transform().basis.z.normalized()
	forward = Plane(Vector3(0, 1, 0), 0).project(forward)
	var right = _head.get_transform().basis.x.normalized()
	var motor = Vector3()
	
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W):
		motor -= forward
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		motor += forward
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A):
		motor -= right
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		motor += right
	
	motor = motor.normalized() * speed
	
	_velocity.x = motor.x
	_velocity.z = motor.z
	_velocity.y -= gravity * delta
	
	#if _grounded and Input.is_key_pressed(KEY_SPACE):
	if Input.is_key_pressed(KEY_SPACE):
		_velocity.y = jump_force
		#_grounded = false
	
	var motion = _velocity * delta
	
	if has_node(terrain):
		var aabb = AABB(Vector3(-0.4, -0.9, -0.4), Vector3(0.8, 1.8, 0.8))
		var terrain_node = get_node(terrain)
		motion = _box_mover.get_motion(get_translation(), motion, aabb, terrain_node)
		global_translate(motion)

	assert(delta > 0)
	_velocity = motion / delta
	
	#var rem = move(motion)
	
	# TODO Fix it, obsolete code
	# if is_colliding():
	# 	var n = get_collision_normal()
	# 	var k = 1.0#clamp(n.y, 0, 1)
	# 	rem = rem.slide(n)*k
	# 	_velocity = _velocity.slide(n)*k
	# 	#rem = n.slide(rem)*k
	# 	#_velocity = n.slide(_velocity)*k
	# 	_grounded = true
	# 	move(rem)
	# else:
	# 	_grounded = false
	#get_node("debug").set_text("Grounded=" + str(_grounded))



