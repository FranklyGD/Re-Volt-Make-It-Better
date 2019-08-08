extends FileDialog

func _ready():
	connect("dir_selected", self, "_dir_selected")
	
func _dir_selected(dir: String):
	owner.load_track(dir)