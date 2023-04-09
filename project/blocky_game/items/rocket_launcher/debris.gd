extends Node3D

const GRAVITY = Vector3(0, -14, 0)
const LIFETIME = 3.0

@onready var _mesh_instance = $MeshInstance
@onready var _terrain : VoxelTerrain = get_node("/root/Main/Game/VoxelTerrain")
@onready var _terrain_tool := _terrain.get_voxel_tool()


var _velocity := Vector3()
var _rotation_axis := Vector3()
var _angular_velocity := 4.0 * TAU * randf_range(-1.0, 1.0)
var _remaining_time := randf_range(0.5, 1.5) * LIFETIME


func _ready():
	rotation = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI))
	scale = Vector3(randf_range(0.5, 1.5), randf_range(0.5, 1.5), randf_range(0.5, 1.5))
	_rotation_axis = \
		Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI)).normalized()


func set_velocity(vel: Vector3):
	_velocity = vel


func _process(delta: float):
	_remaining_time -= delta
	if _remaining_time <= 0:
		queue_free()
		return

	_velocity += GRAVITY * delta

	var trans := transform
	
	trans.basis = trans.basis.rotated(_rotation_axis, _angular_velocity * delta)
	
	var motion := _velocity * delta
	var hit := _terrain_tool.raycast(trans.origin, motion.normalized(), motion.length() * 1.01)
	if hit != null:
		# BOUNCE
		var normal := hit.previous_position - hit.position
		_velocity = _velocity.bounce(normal)
		# Damp on impact
		_velocity *= 0.5
		_angular_velocity *= 0.5
	
	trans.origin += _velocity * delta
	transform = trans
