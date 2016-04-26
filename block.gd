
extends MeshInstance


var voxel_map = null

var _normal_material = null
var _spawn_material = null
var _normal_pos = Vector3(0,0,0)
var _anim_time = 0


func _ready():
	pass
	

func spawn():
#	_spawn_material = FixedMaterial.new()
#	_spawn_material.set_texture(FixedMaterial.PARAM_DIFFUSE, voxel_map.material.get_texture(FixedMaterial.PARAM_DIFFUSE))
#	_spawn_material.set_parameter(FixedMaterial.PARAM_DIFFUSE, Color(1,1,1,0.5))
#	_spawn_material.set_flag(FixedMaterial.FLAG_USE_ALPHA, true)
	#_spawn_material.set_blend_mode(Material.BLEND_MODE_MIX)
	#set_material_override(_spawn_material)
	#set_material_override(voxel_map.material)
	_normal_pos = get_translation()
	set_process(true)


func _process(delta):
	_anim_time += delta
	var k = _anim_time
	if k < 1.0:
		var pos = _normal_pos
		pos.y -= (1-k)*(1-k) * 64.0
		set_translation(pos)
	else:
		set_translation(_normal_pos)
		set_process(false)
	
#	var color = _spawn_material.get_parameter(FixedMaterial.PARAM_DIFFUSE)
#	if color.a < 1.0:
#		color.a += (0.1*delta)
#		if color.a >= 1.0:
#			set_material_override(voxel_map.material)
#			set_process(false)
#			_spawn_material = null
#		else:
#			color.r = color.a
#			color.g = color.a
#			color.b = color.a
#			_spawn_material.set_parameter(FixedMaterial.PARAM_DIFFUSE, color)


