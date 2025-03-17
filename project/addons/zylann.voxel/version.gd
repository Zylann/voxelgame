
# Temporary shim to account for the absence of methods
# in versions prior to 1.2

static func get_major() -> int:
	if VoxelEngine.has_method(&"get_version_major"):
		return VoxelEngine.call(&"get_version_major")
	return 1


static func get_minor() -> int:
	if VoxelEngine.has_method(&"get_version_minor"):
		return VoxelEngine.call(&"get_version_minor")
	return 1


static func get_patch() -> int:
	if VoxelEngine.has_method(&"get_version_patch"):
		return VoxelEngine.call(&"get_version_patch")
	return 0
