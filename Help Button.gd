extends MenuButton

var popup_menu = get_popup()
var options = [
	["Controls", funcref(self, "show_controls")]
]

onready var window_controls = $"./../../../Controls Window"

func _ready():
	for item in options:
		popup_menu.add_item(item[0])

	popup_menu.connect("index_pressed", self, "_index_pressed")

func _index_pressed(index):
	options[index][1].call_func()
	
func show_controls():
	window_controls.visible = true