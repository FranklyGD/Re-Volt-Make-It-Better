extends Spatial
class_name TrackInfo

var track_name : String

var starting_position = Vector3.ZERO
var starting_position_reverse = Vector3.ZERO
var starting_rotation = 0
var starting_rotation_reverse = 0

var imgeo = ImmediateGeometry.new()

func _init(file_path: String):
	var material = ShaderMaterial.new()
	var shader = load("res://Handle.shader")
	material.shader = shader
	material.set_shader_param("fade", 0.5)
	
	imgeo.material_override = material
	
	var file = File.new()
	file.open(file_path, File.READ)
	read(file)

func _ready():
	set_owner(get_node("/root/Re-Volt Editor"))
	add_child(imgeo)
	
func _process(delta):
	imgeo.clear()
	imgeo.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	DrawingTools.arrow(imgeo, starting_position, Vector3.FORWARD.rotated(Vector3.DOWN, starting_rotation), starting_position - owner.camera.transform.origin)
	
	imgeo.end()

func read(file: File):
	while not file.eof_reached():
		var line = file.get_line()
		var data = line.split(";")[0]
		var words = PoolStringArray()
		
		# Seperate words from between white spaces
		for word in data.split(" ", false):
			words += word.split("\t", false)
		if words.size() == 0:
			continue
			
		match words[0]:
			"NAME":
				# First word will always have opening quote
				var name = words[1].substr(1, words[1].length())
				for i in range(2, words.size()):
					var word = words[i]
					name += " " + word.trim_suffix("'")
				track_name = name
			"STARTPOS":
				starting_position = Vector3(words[1].to_float() / 100, words[2].to_float() / -100, words[3].to_float() / -100)
			"STARTROT":
				starting_rotation = words[1].to_float() * 2 * PI
			"STARTPOSREV":
				starting_position_reverse = Vector3(words[1].to_float() / 100, words[2].to_float() / -100, words[3].to_float() / -100)
			"STARTROTREV":
				starting_rotation_reverse = words[1].to_float() * 2 * PI
		pass