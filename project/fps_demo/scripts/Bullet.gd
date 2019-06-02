extends RigidBody

signal painting

enum BULLET_TYPE {
	BALL = -1,                      # Bouncy ball
	ADD = 0,                        # Add terrain
	DELETE = 1                      # Delete terrain
}


var terrain
var type 					= BULLET_TYPE.BALL
var GROWTH_SPEED:Vector3 	= Vector3(0.01,0.01,0.01)
var MIN_DISTANCE:float		= 1.5
var LIFE_TIME:int			= 60
var growth_ticker:int		= 0
var sound_played:bool 		= false


func _ready():	
	if(type != BULLET_TYPE.BALL):
		terrain = get_node("../VoxelTerrain")
	
	bounce = 2.0
	
	# Enable bullet collision detection
	contact_monitor = true
	contacts_reported = 1
	connect("body_entered", self, "_on_bullet_hit")

	var mat = SpatialMaterial.new()
	if(type == BULLET_TYPE.ADD):
		mat.albedo_color = Color(1,1,1,1)
	elif type == BULLET_TYPE.DELETE:
		mat.albedo_color = Color(0,0,0,1)
	else:
		mat.albedo_color = Color( rand_range(0,1), rand_range(0,1), rand_range(0,1), 1 )
	$Mesh.set_surface_material(0, mat)

	var death_timer = Timer.new()
	add_child(death_timer)
	death_timer.connect("timeout", self, "_on_life_timeout")
	death_timer.start(LIFE_TIME)


func _on_bullet_hit(body):
	if not sound_played and body.name != "Player":
		$AudioStreamPlayer3D.play()
		sound_played = true
		
	if type == BULLET_TYPE.BALL and OS.get_ticks_msec() - growth_ticker > 100:
		scale += GROWTH_SPEED
		mass += GROWTH_SPEED.x
		growth_ticker = OS.get_ticks_msec()
	if body.name == "VoxelTerrain" and type != BULLET_TYPE.BALL:
		paint_sphere(global_transform.origin, 3.5, type)
		queue_free()

			

func _on_life_timeout():
	queue_free()


func paint_sphere(center, fradius, type):
	
	# Creates a new VoxelTool each call, so if you want to retain data, put it in a global function (not in Bullet since it gets destroyed)
	var vt = terrain.get_voxel_tool()
	
	# Return if trying to add a block within MIN_DISTANCE of the player
	if type == BULLET_TYPE.ADD and (center - $"../Player".global_transform.origin).length() <= fradius+MIN_DISTANCE:
		return
	
	if "smooth_meshing_enabled" in terrain and terrain.smooth_meshing_enabled:
		vt.channel = VoxelBuffer.CHANNEL_ISOLEVEL
	
	if(type == BULLET_TYPE.ADD):
		vt.mode = VoxelTool.MODE_ADD
		vt.value = 1
		print ("adding")
	elif(type == BULLET_TYPE.DELETE):
		vt.mode = VoxelTool.MODE_REMOVE
		vt.value = 0
		print ("removing")
	
	vt.do_sphere(global_transform.origin, 3.5)
