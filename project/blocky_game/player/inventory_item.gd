
const TYPE_BLOCK = 0
const TYPE_ITEM = 1

var type := TYPE_BLOCK
var id := 0
#var count := 0

# TODO Can't type hint self
func duplicate():
	var d = get_script().new()
	d.type = type
	d.id = id
	return d
