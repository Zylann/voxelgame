extends Spatial

const LIFETIME = 10.0

const DebrisScene = preload("./debris.tscn")
const ExplosionScene = preload("./rocket_explosion.tscn")

onready var _terrain : VoxelTerrain = get_node("../VoxelTerrain")
onready var _terrain_tool := _terrain.get_voxel_tool()

var _direction := Vector3(0, 0, 1)
var _speed := 20.0
var _remaining_time := LIFETIME


func set_direction(direction: Vector3):
	assert(is_inside_tree())
	direction += Vector3(0.0001, 0.0001, 0.001) # Haaaaak
	_direction = direction.normalized()
	look_at(global_transform.origin + _direction, Vector3(0, 1, 0))


func _physics_process(delta: float):
	_remaining_time -= delta
	if _remaining_time <= 0:
		queue_free()
		return
	
	var trans = global_transform
	var crossed_distance := _speed * delta
	var motion := crossed_distance * _direction
	
	var hit = _terrain_tool.raycast(trans.origin, _direction, crossed_distance)
	if hit != null:
		# EXPLODE
		_terrain_tool.do_sphere(hit.position, 4.0)
		
		var explosion = ExplosionScene.instance()
		explosion.translation = trans.origin
		get_parent().add_child(explosion)

		# Create debris
		for i in 30:
			var debris = DebrisScene.instance()
			var debris_velocity := \
				Vector3(rand_range(-1, 1), rand_range(-1, 1), rand_range(-1, 1)).normalized()
			debris_velocity *= rand_range(5.0, 30.0)
			debris.set_velocity(debris_velocity)
			debris.translation = trans.origin
			get_parent().add_child(debris)
		queue_free()
			
	else:
		trans.origin += motion
		global_transform = trans
