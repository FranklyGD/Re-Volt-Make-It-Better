extends MenuButton

export(NodePath) var open_track_window_path
var open_track_window

var save_only_options = PopupMenu.new()

onready var options = [
	["Open Track Folder...", funcref(self, "open_file_menu")],
	["Save All", funcref(self, "save_track")]
]

onready var save_options = [
	["Position", funcref(owner, "save_pos")],
	["AI", funcref(owner, "save_ai")],
	["Track Zone", funcref(owner, "save_tz")]
]

func _ready():
	open_track_window = get_node(open_track_window_path)
	
	var menu = get_popup()
	for item in options:
		menu.add_item(item[0])
	
	save_only_options.set_name("Save Only")
	menu.add_child(save_only_options)
	menu.add_submenu_item("Save Only","Save Only")
	
	for item in save_options:
		save_only_options.add_item(item[0])
		
	save_only_options.set_item_disabled(2, true) # Zone editing is disabled for now
		
	menu.connect("index_pressed", self, "_index_pressed")
	save_only_options.connect("index_pressed", self, "_save_index_pressed")

func _index_pressed(index):
	options[index][1].call_func()
	
func _save_index_pressed(index):
	save_options[index][1].call_func()

# Option Functions
func open_file_menu():
	open_track_window.visible = true

func save_track():
	owner.save_pos()
	owner.save_ai()
	owner.save_tz()