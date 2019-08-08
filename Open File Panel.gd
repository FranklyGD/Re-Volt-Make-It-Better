extends Control

var dir = Directory.new()
var file = File.new()

var dir_name : String
var dir_path : String

onready var path_input = $"Path Input"
onready var warning = $"Warning Message"
onready var name_display = $"Track Name"
onready var open_button = $"Open Button"
var geom = ImmediateGeometry.new()

func _ready():
	validate(path_input.text)

func _on_Path_Input_text_changed(new_text):
	validate(new_text)

func _on_Open_Button_pressed():
	owner.load_track(dir_path)
	visible = false

func validate(path):
	var valid_folder = dir.dir_exists(path)
	warning.visible = not valid_folder
	if valid_folder:

		# Split track name from path
		dir.open(path)
		dir_path = dir.get_current_dir()
		dir_name = dir_path.get_file()

		if dir_name:
			name_display.text = dir_name
		else:
			name_display.text = "<none>"
	else:
		name_display.text = ""

	open_button.disabled = not valid_folder and not dir_name