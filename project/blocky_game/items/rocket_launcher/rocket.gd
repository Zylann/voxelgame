extends Node3D

const LIFETIME = 10.0

const DebrisScene = preload("./debris.tscn")
const ExplosionScene = preload("./rocket_explosion.tscn")

@onready var _terrain : VoxelTerrain = get_node("../VoxelTerrain")
@onready var _terrain_tool := _terrain.get_voxel_tool()

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
		# Spent too long not hitting anything
		queue_free()
		return
	
	var trans = global_transform
	var crossed_distance := _speed * delta
	var motion := crossed_distance * _direction
	
	var hit = _terrain_tool.raycast(trans.origin, _direction, crossed_distance)
	if hit != null:
		_explode(hit.position, trans.origin)
	else:
		trans.origin += motion
		global_transform = trans


func _explode(voxel_hit_pos: Vector3, explosion_pos: Vector3):
	var mp := get_tree().get_multiplayer()
	if mp.has_multiplayer_peer():
		if mp.is_server():
			_terrain_tool.do_sphere(voxel_hit_pos, 4.0)
			rpc(&"receive_explode", explosion_pos)
			_create_explosion_vfx(explosion_pos)
			queue_free()
		# Else, clients don't do anything. Clients could rely on their local copy of the terrain
		# to find when the collision occurs, but it can lead to false positives if terrain is synced
		# out of order, so it's more reliable to explicitely be told when to play the explosion
	else:
		_create_explosion_vfx(explosion_pos)
		queue_free()


@rpc("authority", "call_remote", "reliable", 0)
func receive_explode(pos: Vector3):
	_create_explosion_vfx(pos)
	queue_free()


func _create_explosion_vfx(explosion_pos: Vector3):
	# VFX are not created as children of the rocket because it gets destroyed shortly after.
	
	var explosion = ExplosionScene.instantiate()
	explosion.position = explosion_pos
	get_parent().add_child(explosion)
	
	# Create debris
	for i in 30:
		var debris = DebrisScene.instantiate()
		var debris_velocity := \
			Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		debris_velocity *= randf_range(5.0, 30.0)
		debris.set_velocity(debris_velocity)
		debris.position = explosion_pos
		get_parent().add_child(debris)


