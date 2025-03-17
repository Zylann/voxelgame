extends Node

@onready var _terrain : VoxelTerrain = $VoxelTerrain
var _voxel_tool : VoxelTool
var _library : VoxelBlockyLibrary

var _air_id := 0
var _water_ids := PackedInt32Array()

var _update_queue := []
var _next_update_queue := []
var _tick_interval := 0.125
var _time_before_next_tick := 0.0

# var _place_counter := 100


func _ready() -> void:
	_voxel_tool = _terrain.get_voxel_tool()
	_voxel_tool.channel = VoxelBuffer.CHANNEL_TYPE
	
	_library = _terrain.mesher.library
	
	_air_id = _library.get_model_index_from_resource_name("air")
	for i in 8:
		_water_ids.append(_library.get_model_index_from_resource_name(str("water", i)))
	

func _place_water(pos: Vector3i):
	var max_level := _water_ids.size() - 1
	var model_id := _water_ids[max_level]
	_voxel_tool.set_voxel(pos, model_id)
	_next_update_queue.append(pos)


func _process(delta: float) -> void:
	_time_before_next_tick -= delta
	if _time_before_next_tick <= 0.0:
		_time_before_next_tick = _tick_interval
		_tick_voxels()

	# if _place_counter > 0:
	# 	if _voxel_tool.is_area_editable(AABB(Vector3(0,0,5), Vector3(1,1,1)).grow(16)):
	# 		_place_counter -= 1
	# 		if _place_counter == 0:
	# 			_place_water(Vector3i(0,0,-5))
	# 			print("Placed")
	
	DDD.set_text("Voxel updates: ", _next_update_queue.size())


func _input(event: InputEvent):
	if event is InputEventKey:
		if event.pressed:
			if event.keycode == KEY_P:
				_place_water(Vector3i(0,0,-5))


const _horizontal_neighbor_directions : Array[Vector3i] = [
	Vector3i(-1, 0, 0),
	Vector3i(1, 0, 0),
	Vector3i(0, 0, -1),
	Vector3i(0, 0, 1),
]

func _tick_voxels():
	# Not the most efficient block update system, but should be enough for a demo

	_update_queue.clear()
	
	# Swap queues
	var temp := _next_update_queue
	_next_update_queue = _update_queue
	_update_queue = temp
	
	for queue_item in _update_queue:
		var position : Vector3i = queue_item
		var model_id : int = _voxel_tool.get_voxel(position)
		var abstract_model := _library.get_model(model_id)
		var model := abstract_model as VoxelBlockyModelFluid
		
		if model != null:
			var level := model.level
			var below_pos := position + Vector3i.DOWN
			var below_model_id : int = _voxel_tool.get_voxel(below_pos)
			
			var max_level := _water_ids.size() - 1
			
			if below_model_id == _air_id:
				# Note, this demo only spreads water, it doesn't unspread it.
				# To support removing water, we would have to differenciate sources (of 
				# max level) from falling water. That could be done by having an extra model with
				# max level so it can be differenciated by its ID.
				_voxel_tool.set_voxel(below_pos, _water_ids[max_level])
				_next_update_queue.append(below_pos)
				continue
			
			var below_model := _library.get_model(below_model_id) as VoxelBlockyModelFluid
			if below_model != null:
				if below_model.level < max_level:
					_voxel_tool.set_voxel(below_pos, _water_ids[max_level])
					_next_update_queue.append(below_pos)
				continue
			
			# Below model is assumed to be solid
			
			if level > 0:
				# Flow sideways
				var next_level := level - 1
				
				for ndir in _horizontal_neighbor_directions:
					var npos := position + ndir
					var nid := _voxel_tool.get_voxel(npos)
					
					if nid == _air_id:
						_voxel_tool.set_voxel(npos, _water_ids[next_level])
						_next_update_queue.append(npos)
						continue
					
					var nm := _library.get_model(nid) as VoxelBlockyModelFluid
					if nm != null:
						if nm.level < next_level:
							_voxel_tool.set_voxel(npos, _water_ids[next_level])
							_next_update_queue.append(npos)
							continue
