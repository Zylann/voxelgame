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



