extends Node3D

@export var speed = 5.0
@export var gravity = 9.8
@export var jump_force = 5.0
@export var head : NodePath

# Not used in this script, but might be useful for child nodes because
# this controller will most likely be on the root
@export var terrain : NodePath

var _velocity = Vector3()
var _grounded = false
var _head = null
var _box_mover = VoxelBoxMover.new()


func _ready():
	_box_mover.set_collision_mask(1) # Excludes rails
	_box_mover.set_step_climbing_enabled(true)
	_box_mover.set_max_step_height(0.5)

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
	
	if _grounded and Input.is_key_pressed(KEY_SPACE):
		_velocity.y = jump_force
		_grounded = false
	
	var motion = _velocity * delta
	
	if has_node(terrain):
		var aabb = AABB(Vector3(-0.4, -0.9, -0.4), Vector3(0.8, 1.8, 0.8))
		var terrain_node = get_node(terrain)
		var prev_motion = motion

		# Modify motion taking collisions into account
		motion = _box_mover.get_motion(position, motion, aabb, terrain_node)

		# Apply motion with a raw translation.
		global_translate(motion)

		# If new motion doesnt move vertically and we were falling before, we just landed
		if abs(motion.y) < 0.001 and prev_motion.y < -0.001:
			_grounded = true

		if _box_mover.has_stepped_up():
			# When we step up, the motion vector will have vertical movement,
			# however it is not caused by falling or jumping, but by snapping the body on
			# top of the step. So after we applied motion, we consider it grounded,
			# and we reset motion.y so we don't induce a "jump" velocity later.
			motion.y = 0
			_grounded = true
		
		# Otherwise, if new motion is moving vertically, we may not be grounded anymore
		elif abs(motion.y) > 0.001:
			_grounded = false

		# TODO Stepping up stairs is quite janky. Minecraft seems to smooth it out a little.
		# That would be a visual-only trick to apply it seems.

	assert(delta > 0)
	# Re-inject velocity from resulting motion
	_velocity = motion / delta



