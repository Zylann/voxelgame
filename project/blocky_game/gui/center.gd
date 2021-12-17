extends Sprite2D

# TODO Get rid if this once viewport modes get fixed!

func _process(delta):
	var rect = get_viewport().get_visible_rect()
	position = rect.size/2.0

