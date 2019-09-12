# Single-file autoload for debug drawing and printing.
# Draw and print on screen from anywhere in a single line of code.
# Find it quickly by naming it "DDD".

extends Node


const TEXT_LINGER_FRAMES = 5
const LINES_LINGER_FRAMES = 1

var _lines = []
var _line_material = null

var _label = null
var _texts = {}


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
		"frame": Engine.get_frames_drawn() + LINES_LINGER_FRAMES,
		"node": g
	})


func _get_line_material():
	if _line_material == null:
		var mat = SpatialMaterial.new()
		mat.flags_unshaded = true
		mat.vertex_color_use_as_albedo = true
		_line_material = mat
	return _line_material


func _process(delta):
	var i = 0
	while i < len(_lines):
		var d = _lines[i]
		if d.frame <= Engine.get_frames_drawn():
			d.node.queue_free()
			_lines[i] = _lines[i - 1]
			_lines.pop_back()
		else:
			i += 1
	
	if _label != null:
		var text = ""
		for key in _texts.keys():
			var t = _texts[key]
			if t.frame <= Engine.get_frames_drawn():
				_texts.erase(key)
			else:
				text = str(text, key, ": ", t.text, "\n")
		_label.text = text


func set_text(key, text):
	if _label == null:
		_label = Label.new()
		add_child(_label)
	_texts[key] = {
		"text": text,
		"frame": Engine.get_frames_drawn() + TEXT_LINGER_FRAMES
	}

