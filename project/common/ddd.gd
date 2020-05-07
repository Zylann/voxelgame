# Single-file autoload for debug drawing and printing.
# Draw and print on screen from anywhere in a single line of code.
# Find it quickly by naming it "DDD".

extends Node


const TEXT_LINGER_FRAMES = 5
const LINES_LINGER_FRAMES = 1
const BOXES_LINGER_FRAMES = 1

var _lines = []

var _canvas_item = null
var _texts = {}

var _boxes = []
var _box_pool = []
var _box_mesh = null

var _line_material_pool = []

var _font = null


func _ready():
	# Meh
	var c = Control.new()
	add_child(c)
	_font = c.get_font("font")
	c.queue_free()
	print("Got font ", _font)


func draw_box(position: Vector3, size: Vector3, color: Color = Color(1,1,1)):
	if _box_mesh == null:
		_box_mesh = _create_wirecube_mesh(Color(1,1,1))
	var mi = _get_box()
	mi.mesh = _box_mesh
	var mat = _get_line_material()
	mat.albedo_color = color
	mi.material_override = mat
	mi.translation = position
	mi.scale = size
	_boxes.append({
		"node": mi,
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES
	})


func draw_line(a, b, color):
	var g = ImmediateGeometry.new()
	g.material_override = _get_line_material()
	g.begin(Mesh.PRIMITIVE_LINES)
	g.set_color(color)
	g.add_vertex(a)
	g.add_vertex(b)
	g.end()
	add_child(g)
	_lines.append({
		"node": g,
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES,
	})


func set_text(key, text):
	_texts[key] = {
		"text": text,
		"frame": Engine.get_frames_drawn() + TEXT_LINGER_FRAMES
	}


func _get_box():
	var mi
	if len(_box_pool) == 0:
		mi = MeshInstance.new()
		mi.mesh = _box_mesh
		add_child(mi)
	else:
		mi = _box_pool[-1]
		_box_pool.pop_back()
	return mi


func _recycle_box(mi):
	mi.hide()
	_box_pool.append(mi)


func _get_line_material():
	var mat
	if len(_line_material_pool) == 0:
		mat = SpatialMaterial.new()
		mat.flags_unshaded = true
		mat.vertex_color_use_as_albedo = true
	else:
		mat = _line_material_pool[-1]
		_line_material_pool.pop_back()
	return mat


func _recycle_line_material(mat):
	_line_material_pool.append(mat)


func _process_delayed_free(items):
	var i = 0
	while i < len(items):
		var d = items[i]
		if d.frame <= Engine.get_frames_drawn():
			_recycle_line_material(d.node.material_override)
			d.node.queue_free()
			items[i] = items[i - 1]
			items.pop_back()
		else:
			i += 1


func _process(delta):
	_process_delayed_free(_lines)
	_process_delayed_free(_boxes)

	# Progressively delete boxes
	if len(_box_pool) > 0:
		var last = _box_pool[-1]
		_box_pool.pop_back()
		last.queue_free()

	# Remove text lines after some time
	for key in _texts.keys():
		var t = _texts[key]
		if t.frame <= Engine.get_frames_drawn():
			_texts.erase(key)

	# Update canvas
	if _canvas_item == null:
		_canvas_item = Node2D.new()
		_canvas_item.position = Vector2(8, 8)
		_canvas_item.connect("draw", self, "_on_CanvasItem_draw")
		add_child(_canvas_item)
	_canvas_item.update()


func _on_CanvasItem_draw():
	var ci = _canvas_item
	var fg_color = Color(1,1,1)
	var bg_color = Color(0.3, 0.3, 0.3, 0.8)

	var ascent = Vector2(0, _font.get_ascent())
	var pos = Vector2()
	var xpad = 2
	var ypad = 1
	var font_offset = ascent + Vector2(xpad, ypad)
	var line_height = _font.get_height() + 2 * ypad

	for key in _texts.keys():
		var t = _texts[key]
		var text = str(key, ": ", t.text, "\n")
		var ss = _font.get_string_size(text)
		ci.draw_rect(Rect2(pos, Vector2(ss.x + xpad * 2, line_height)), bg_color)
		ci.draw_string(_font, pos + font_offset, text, fg_color)
		pos.y += line_height


static func _create_wirecube_mesh(color = Color(1,1,1)):
	var positions = PoolVector3Array([
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1)
	])
	var colors = PoolColorArray([
		color, color, color, color,
		color, color, color, color,
	])
	var indices = PoolIntArray([
		0, 1,
		1, 2,
		2, 3,
		3, 0,

		4, 5,
		5, 6,
		6, 7,
		7, 4,

		0, 4,
		1, 5,
		2, 6,
		3, 7
	])
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = positions
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh

