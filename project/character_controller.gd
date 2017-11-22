extends Spatial

const BoxPhysics = preload("res://box_physics.gd")

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
	
	motion = move_with_box_physics(motion)
	
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


# TODO There is room for optimization, but I'll leave it like this for now, it doesn't cause any lag
func move_with_box_physics(motion):
	#var debug3d = get_node("../Debug3D")
	
	var pos = get_translation()
	var box = BoxPhysics.box_from_center_extents(pos, Vector3(0.4, 0.9, 0.4))
	
	var expanded_box = BoxPhysics.expand_with_vector(box, motion)
	#debug3d.draw_wire_box(expanded_box, Color(0,1,0,1))
	
	var potential_boxes = []
	
	# Collect collisions with the terrain
	if has_node(terrain):
		var voxel_terrain = get_node(terrain)
		var voxels = voxel_terrain.get_storage()
		
		var min_x = int(floor(expanded_box.position.x))
		var min_y = int(floor(expanded_box.position.y))
		var min_z = int(floor(expanded_box.position.z))
		
		var max_x = int(ceil(expanded_box.end.x))
		var max_y = int(ceil(expanded_box.end.y))
		var max_z = int(ceil(expanded_box.end.z))
		
		var x = min_x
		var y = min_y
		var z = min_z
		
		while z < max_z:
			while y < max_y:
				while x < max_x:
					
					var voxel_type = voxels.get_voxel(x,y,z, 0)
					if voxel_type != 0:
						var voxel_box = AABB(Vector3(x,y,z), Vector3(1,1,1))
						potential_boxes.append(voxel_box)
						#debug3d.draw_wire_box(voxel_box)
					
					x += 1
				x = min_x
				y += 1
			y = min_y
			z += 1
	
	motion = BoxPhysics.get_motion(box, motion, potential_boxes)
	# TODO If any Godot physics is used here, it will break box physics and you'll fall through the map!
	# TODO Latest KinematicBody fucks up my motion, no idea why. Changed to Spatial
	#move_and_slide(motion)
	global_translate(motion)
	return motion







