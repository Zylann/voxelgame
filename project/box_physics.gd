
const EPSILON = 0.001

# Gets the transformed vector for moving a box and slide.
# This algorithm is free from tunnelling for axis-aligned movement,
# except in some high-speed diagonal cases or huge size differences:
# For example, if a box is fast enough to have a diagonal motion jumping from A to B,
# it will pass through C if that other box is the only other one:
#
#  o---o
#  | A |
#  o---o
#          o---o
#          | C |
#          o---o
#                  o---o
#                  | B |
#                  o---o
#
# TODO one way to fix this would be to try a "hot side" projection instead
#
static func get_motion(box, motion, other_boxes):
	# The bounding box is expanded to include it's estimated version at next update.
	# This also makes the algorithm tunnelling-free
	var expanded_box = expand_with_vector(box, motion)
	
	var colliding_boxes = []
	for other in other_boxes:
		if expanded_box.intersects(other):
			colliding_boxes.append(other)
	
	if colliding_boxes.size() == 0:
		return motion
	#print("Colliding: ", colliding_boxes.size())
	
	var new_motion = motion
	
	for other in colliding_boxes:
		new_motion.y = calculate_y_offset(other, box, new_motion.y)
	box.position.y += new_motion.y
	
	for other in colliding_boxes:
		new_motion.x = calculate_x_offset(other, box, new_motion.x)
	box.position.x += new_motion.x
	
	for other in colliding_boxes:
		new_motion.z = calculate_z_offset(other, box, new_motion.z)
	box.position.z += new_motion.z
	
	return new_motion


static func expand_with_vector(box, v):
	if v.x > 0:
		box.size.x += v.x
	elif v.x < 0:
		box.position.x += v.x
		box.size.x -= v.x
	if v.y > 0:
		box.size.y += v.y
	elif v.y < 0:
		box.position.y += v.y
		box.size.y -= v.y
	if v.z > 0:
		box.size.z += v.z
	elif v.z < 0:
		box.position.z += v.z
		box.size.z -= v.z
	return box


static func calculate_z_offset(box, other, motion_z):
	if other.end.y <= box.position.y || other.position.y >= box.end.y:
		return motion_z
	if other.end.x <= box.position.x || other.position.x >= box.end.x:
		return motion_z
	if motion_z > 0.0 and other.end.z <= box.position.z:
		var off = box.position.z - other.end.z - EPSILON
		if off < motion_z:
			motion_z = off
	if motion_z < 0.0 and other.position.z >= box.end.z:
		var off = box.end.z - other.position.z + EPSILON
		if off > motion_z:
			motion_z = off
	return motion_z


static func calculate_x_offset(box, other, motion_x):
	if other.end.z <= box.position.z || other.position.z >= box.end.z:
		return motion_x
	if other.end.y <= box.position.y || other.position.y >= box.end.y:
		return motion_x
	if motion_x > 0.0 and other.end.x <= box.position.x:
		var off = box.position.x - other.end.x - EPSILON
		if off < motion_x:
			motion_x = off
	if motion_x < 0.0 and other.position.x >= box.end.x:
		var off = box.end.x - other.position.x + EPSILON
		if off > motion_x:
			motion_x = off
	return motion_x


static func calculate_y_offset(box, other, motion_y):
	if other.end.z <= box.position.z || other.position.z >= box.end.z:
		return motion_y
	if other.end.x <= box.position.x || other.position.x >= box.end.x:
		return motion_y
	if motion_y > 0.0 and other.end.y <= box.position.y:
		var off = box.position.y - other.end.y - EPSILON
		if off < motion_y:
		    motion_y = off
	if motion_y < 0.0 and other.position.y >= box.end.y:
		var off = box.end.y - other.position.y + EPSILON
		if off > motion_y:
		    motion_y = off
	return motion_y


static func box_from_center_extents(center, extents):
	return AABB(center - extents, 2.0*extents)
