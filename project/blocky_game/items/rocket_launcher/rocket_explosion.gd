extends Node3D

@onready var _particles = $Particles
@onready var _animation_player = $AnimationPlayer


func _ready():
	_particles.emitting = true
	_animation_player.play("explode")


func _on_Timer_timeout():
	queue_free()
