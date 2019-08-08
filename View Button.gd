extends MenuButton

var popup_menu = get_popup()
var options = [
	["Position Nodes", funcref(self, "toggle_view_pos")],
	["AI Segments", funcref(self, "toggle_view_ai")],
	["Track Zones", funcref(self, "toggle_view_track_zone")]
]

func _ready():
	for item in options:
		popup_menu.add_check_item(item[0])
		
	popup_menu.connect("index_pressed", self, "_index_pressed")
	owner.connect("on_load", self, "_on_track_load")

func _on_track_load():
	# Disable options if the information doesn't exit
	popup_menu.set_item_disabled(0, owner.positionData == null)
	popup_menu.set_item_disabled(1, owner.aiData == null)
	popup_menu.set_item_disabled(2, owner.trackZoneData == null)

	# Reset View
	popup_menu.set_item_checked(0, true)
	popup_menu.set_item_checked(1, true)
	popup_menu.set_item_checked(2, true)

func _index_pressed(index):
	options[index][1].call_func()

# View toggle functions
func toggle_view_node(index, node):
	popup_menu.toggle_item_checked(index)
	var toggle = popup_menu.is_item_checked(index)
	if node:
		node.viewable = toggle

func toggle_view_pos():
	toggle_view_node(0, owner.positionData)

func toggle_view_ai():
	toggle_view_node(1, owner.aiData)

func toggle_view_track_zone():
	toggle_view_node(2, owner.trackZoneData)