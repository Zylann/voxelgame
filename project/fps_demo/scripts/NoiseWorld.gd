extends Spatial

onready var terrain = $VoxelTerrain

const MATERIAL = preload("res://fps_demo/materials/grass-rock2.material")

func _ready():
	randomize()
	update_noise_ui()
	
func _input(event):
	if event is InputEventKey and Input.is_key_pressed(KEY_N):
		randomize_terrain()
		
	if event is InputEventKey and Input.is_key_pressed(KEY_TAB):
		$UI_Noise.visible = !$UI_Noise.visible
		$UI.visible = !$UI.visible


func randomize_terrain():	
	terrain.queue_free()
	terrain = VoxelLodTerrain.new()
	terrain.name = "VoxelTerrain"
	
	terrain.stream = VoxelStreamNoise.new()
	terrain.stream.noise = OpenSimplexNoise.new()
	terrain.stream.noise.seed = randi()								# Int (0): 		0 to 2147483647
	terrain.stream.noise.octaves = 1+randi()%5						# Int (3): 		1 - 6 
	terrain.stream.noise.period = rand_range(0.1, 256)				# Float (64): 	0.1 - 256.0 
	terrain.stream.noise.persistence = randf()						# Float (0.5): 	0.0 - 1.0
	terrain.stream.noise.lacunarity = rand_range(0.1, 4)			# Float (2): 	0.1 - 4.0
	update_noise_ui()
		
	terrain.lod_count = 8
	terrain.lod_split_scale = 3
	terrain.viewer_path = "/root/Spatial/Player"
	terrain.set_material(MATERIAL)
	add_child(terrain)


func update_noise_ui():
	$UI_Noise/Seed.text = "Seed: " + String(terrain.stream.noise.seed)
	$UI_Noise/Octaves.text = "Octaves: " + String(terrain.stream.noise.octaves)
	$UI_Noise/Period.text = "Period: " + String(terrain.stream.noise.period).substr(0,4)
	$UI_Noise/Persistence.text = "Persistence: " + String(terrain.stream.noise.persistence).substr(0,4)
	$UI_Noise/Lacunarity.text = "Lacunarity: " + String(terrain.stream.noise.lacunarity).substr(0,4)
