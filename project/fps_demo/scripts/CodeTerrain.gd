""" This file shows you how to create a Voxel Tools terrain from code """

extends Spatial

const MyStream = preload ("MyStream.gd")

const MATERIAL = preload("res://fps_demo/materials/grass-rock.material")
const HEIGHT_MAP = preload("res://blocky_terrain/noise_distorted.png")

var terrain

func _ready():
	create_terrain()
	
func _input(event):
	
	if event is InputEventKey and Input.is_key_pressed(KEY_DELETE):
		terrain.free()
		
	if event is InputEventKey and Input.is_key_pressed(KEY_N):
		create_terrain()		

	
func create_terrain():
	
### Folllow the instructions to use the various types of terrains available
	
### 1. Choose VoxelTerrain or VoxelLodTerrain

	terrain = VoxelTerrain.new()
#	terrain = VoxelLodTerrain.new()


### 2. Select Blocky=0 or Smooth=1  (VLT is always smooth)

	var voxel_type = 1
	
	
### 3. Pick one of the following three example sections:
	
## A. Custom GDScript stream 
## This generates a 3D sine wave with GDScript

	terrain.stream = MyStream.new()
	terrain.stream.voxel_type = voxel_type
	

## B. C++ Stream (VT Only)
## This generates a 3D sine wave from C++ and is considerably faster.
## This example is hard coded to draw blocky voxels so doesn't work with VLT, but you could write your own in C++.

#	terrain.stream = VoxelStreamTest.new() 


## C. Image based stream

#	terrain.stream = VoxelStreamImage.new()
#	terrain.stream.image = HEIGHT_MAP
#	terrain.stream.channel = voxel_type
#	$Player.translate(Vector3(0,35,0))		# Not required, just aids the demo


## D. 3D Noise stream (Smooth only)

#	terrain.stream = VoxelStreamNoise.new()
#	terrain.stream.noise = OpenSimplexNoise.new()
#	$Player.translate(Vector3(0,200,0))		# Not required, just aids the demo


### 4. Uncomment the one appropriate block below

## VoxelTerrain	

	terrain.voxel_library = VoxelLibrary.new()
	if voxel_type==1:
		terrain.smooth_meshing_enabled = true	
	terrain.view_distance = 256	
	terrain.set_material(0, MATERIAL)


## VoxelLodTerrain		

#	terrain.lod_count = 8
#	terrain.lod_split_scale = 3
#	terrain.set_material(MATERIAL)


### 5. Stop - Applicable to all

	terrain.viewer_path = "/root/Spatial/Player"
	terrain.name = "VoxelTerrain"
	add_child(terrain)

