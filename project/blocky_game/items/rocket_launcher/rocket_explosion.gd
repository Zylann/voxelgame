extends Spatial

onready var _particles = $Particles


func _ready():
	_particles.emitting = true


func _on_Timer_timeout():
	queue_free()
