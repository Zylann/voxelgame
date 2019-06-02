extends KinematicBody

const 		MOUSE_SENSITIVITY:float 	= 0.1
const  		GRAVITY:float				= -9.8
const 		ACCEL:float					= 8.0
const 		DEACCEL:float				= 16.0
onready var MAX_FLOOR_ANGLE:float 		= deg2rad(60)
export var	WALK_SPEED:float 			= 12.0
export var  JUMP_SPEED:float			= 15.0
export var	jump_is_jetpack:bool		= false
var   		velocity:Vector3			= Vector3()  # Current velocity direction

const 		Bullet						= preload("Bullet.gd")
var 		firing:bool 				= false
var 		firing_type					= Bullet.BULLET_TYPE.BALL
onready var firing_tick:int				= OS.get_ticks_msec()
export var 	FIRING_DELAY				= 150

onready var	camera_pullback_tick:int 	= OS.get_ticks_msec()		# Pullback Timer
export var 	CAMERA_PULLBACK_DELAY		= 1000						# Wait this many ms before pulling back
export var 	CAMERA_POS_CLOSE:Vector3 	= Vector3(0, 0.3, 0)		# Vectors that the two settings below lerp between
export var 	CAMERA_POS_FAR:Vector3		= Vector3(0, 3.5, 7)
var			camera_max_lerp:float		= 1.0						# User set max lerp position between 0 and 1
var 	   	camera_pos_lerp:float		= 0.0						# Current lerp position between 0 and camera_max_lerp 


func _ready():
	randomize()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	
	#### Update Player
	
	var direction = Vector3() 						# Where does the player want to move
	var facing_direction = global_transform.basis	# Get camera facing direction

	if Input.is_action_pressed("move_forward"):		# Fix: Can move around in the air, no momentum, so can also climb steep walls.
		direction -= facing_direction.z			
	if Input.is_action_pressed("move_backward"):
		direction += facing_direction.z
	if Input.is_action_pressed("move_left"):
		direction += -facing_direction.x
	if Input.is_action_pressed("move_right"):
		direction += +facing_direction.x
	if  Input.is_action_pressed("jump") and (jump_is_jetpack or is_on_floor()):
		velocity.y = JUMP_SPEED
	
	#direction.y = 0
	direction = direction.normalized()
	
	# Apply gravity to downward velocity
	velocity.y += delta*GRAVITY
	
	var hvelocity = velocity				# Apply desired direction to horizontal velocity
	hvelocity.y = 0
	
	var target = direction*WALK_SPEED
	var accel
	if (direction.dot(hvelocity) > 0):
		accel = ACCEL
	else:
		accel = DEACCEL
	
	hvelocity = hvelocity.linear_interpolate(target, accel*delta)
	
	velocity.x = hvelocity.x
	velocity.z = hvelocity.z

	velocity = move_and_slide(velocity, Vector3(0, 1, 0), true)


	#### Continuous fire
	if firing and OS.get_ticks_msec()-firing_tick>FIRING_DELAY:
		firing_tick = OS.get_ticks_msec()
		shoot_bullet()
		
	
	#### Update Camera
	
	if camera_max_lerp>0:
		check_camera_bounds()
		
		
	#### Update HUD
	
	$"../UI/VBox/FPS".text = "FPS: " + String(Engine.get_frames_per_second())	
	$"../UI/VBox/Position".text = "Position: " + String(global_transform.origin)	



# If follow camera is on, and hits the terrain, pull it in closer to the player 
func check_camera_bounds():
	var space_state = get_world().direct_space_state
	var pos = $CamNode/Camera.global_transform.origin

	# Raycast two unit around camera for rudimentary collision detection. (Maybe switch Camera parent to physicsbody?)
	var result0 = space_state.intersect_ray(pos, pos + 2*$CamNode/Camera.global_transform.basis.z, [self])  # Behind
	var result1 = space_state.intersect_ray(pos, pos - 2*$CamNode/Camera.global_transform.basis.z, [self])  # Front
	var result2 = space_state.intersect_ray(pos, pos + 2*$CamNode/Camera.global_transform.basis.x, [self])	# Right
	var result3 = space_state.intersect_ray(pos, pos - 2*$CamNode/Camera.global_transform.basis.x, [self])	# Left
	var result4 = space_state.intersect_ray(pos, pos + 2*$CamNode/Camera.global_transform.basis.y, [self])	# Above
	var result5 = space_state.intersect_ray(pos, pos - 2*$CamNode/Camera.global_transform.basis.y, [self])	# Below

	if result0 or result1 or result2 or result3 or result4 or result5:
		camera_pos_lerp -= .025
		camera_pos_lerp = clamp(camera_pos_lerp, 0, camera_max_lerp)
		camera_pullback_tick = OS.get_ticks_msec()
		move_camera(camera_pos_lerp)

	else:
		if OS.get_ticks_msec() - camera_pullback_tick > CAMERA_PULLBACK_DELAY:
			camera_pos_lerp += .01
			camera_pos_lerp = clamp(camera_pos_lerp, 0, camera_max_lerp)
			move_camera(camera_pos_lerp)



func move_camera(lerp_val:float) -> void:
	var t = $CamNode/Camera.get_transform()
	var offset = CAMERA_POS_CLOSE.linear_interpolate(CAMERA_POS_FAR, lerp_val)
	t.origin = CAMERA_POS_CLOSE + offset
	$CamNode/Camera.set_transform(t)



func shoot_bullet():
	$AudioStreamPlayer.play()

	var bullet = preload("res://fps_demo/support/bullet.tscn").instance()
	var start_pos = $Body/Shoulder/Gun.global_transform.translated(Vector3(0,-1.15,0))
	bullet.set_transform(start_pos)
	bullet.scale = Vector3(.3,.3,.3)
		
	if Input.is_key_pressed(KEY_CONTROL):
		bullet.type = Bullet.BULLET_TYPE.BALL
	else:
		bullet.type = firing_type

	bullet.set_linear_velocity(velocity - $Body/Shoulder/Gun.global_transform.basis.y * 30)
	bullet.connect("painting", self, "_on_terrain_addition")
	get_parent().add_child(bullet)


func _input(event):
	
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(BUTTON_WHEEL_UP):
		camera_max_lerp -= .1
		camera_max_lerp = clamp(camera_max_lerp, 0, 1)

	if event is InputEventMouseButton and Input.is_mouse_button_pressed(BUTTON_WHEEL_DOWN):
		camera_max_lerp += .1
		camera_max_lerp = clamp(camera_max_lerp, 0, 1)
		
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		# Rotate the camera around the player vertically
		$CamNode.rotate_x(deg2rad(-event.relative.y * MOUSE_SENSITIVITY * 0.90625))
		var rot = $CamNode.rotation_degrees
		rot.x = clamp(rot.x, -60, 85)
		$CamNode.rotation_degrees = rot

		# Rotate the gun up and down aligned with the player 
		$Body/Shoulder.rotate_x(deg2rad(-event.relative.y * MOUSE_SENSITIVITY))
		rot = $Body/Shoulder.rotation_degrees
		rot.x = clamp(rot.x, -80, 80)
		$Body/Shoulder.rotation_degrees = rot
		$GunCollisionShape.global_transform = $Body/Shoulder/Gun.global_transform
		
		# Rotate Player left and right
		self.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -1))


	if event is InputEventKey and Input.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



	if event is InputEventMouseButton:
		if Input.is_action_pressed("shoot_add"):
			firing_type = Bullet.BULLET_TYPE.ADD
			firing = true
			firing_tick = OS.get_ticks_msec()
			shoot_bullet()
		elif Input.is_action_pressed("shoot_del"):
			firing_type = Bullet.BULLET_TYPE.DELETE
			firing = true
			firing_tick = OS.get_ticks_msec()
			shoot_bullet()
		elif Input.is_action_just_released("shoot_add") or Input.is_action_just_released("shoot_del"):
			firing = false

