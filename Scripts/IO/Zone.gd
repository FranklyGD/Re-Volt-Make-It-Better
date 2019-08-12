extends StaticBody
class_name Zone

var color = Color.white setget set_color

var imgeo = ImmediateGeometry.new()
var box = CSGBox.new()
var box_shape = CollisionShape.new()

var outline_material = load("res://Handle Obstructed.material").duplicate()
var solid_material = load("res://Handle Obstructed.material").duplicate()

var is_zone_blocking setget _set_blocking
func _set_blocking(value: bool):
	box_shape.disabled = not value # This does not work for some reason

func _init():
	outline_material.set_shader_param("fade", 20)
	outline_material.set_shader_param("limit", 0.25)
	
	solid_material.set_shader_param("fade", 5)
	
	imgeo.material_override = outline_material
	box.material = solid_material
	
	box_shape.shape = BoxShape.new()
	box_shape.disabled = true

func _ready():
	add_child(imgeo)
	add_child(box)
	add_child(box_shape)

func _process(delta):
	imgeo.clear()
	imgeo.begin(Mesh.PRIMITIVE_LINES)

	imgeo.add_vertex(Vector3(1,1,1))
	imgeo.add_vertex(Vector3(-1,1,1))
	imgeo.add_vertex(Vector3(1,-1,1))
	imgeo.add_vertex(Vector3(-1,-1,1))
	imgeo.add_vertex(Vector3(1,1,-1))
	imgeo.add_vertex(Vector3(-1,1,-1))
	imgeo.add_vertex(Vector3(1,-1,-1))
	imgeo.add_vertex(Vector3(-1,-1,-1))

	imgeo.add_vertex(Vector3(1,1,1))
	imgeo.add_vertex(Vector3(1,-1,1))
	imgeo.add_vertex(Vector3(-1,1,1))
	imgeo.add_vertex(Vector3(-1,-1,1))
	imgeo.add_vertex(Vector3(1,1,-1))
	imgeo.add_vertex(Vector3(1,-1,-1))
	imgeo.add_vertex(Vector3(-1,1,-1))
	imgeo.add_vertex(Vector3(-1,-1,-1))

	imgeo.add_vertex(Vector3(1,1,1))
	imgeo.add_vertex(Vector3(1,1,-1))
	imgeo.add_vertex(Vector3(-1,1,1))
	imgeo.add_vertex(Vector3(-1,1,-1))
	imgeo.add_vertex(Vector3(1,-1,1))
	imgeo.add_vertex(Vector3(1,-1,-1))
	imgeo.add_vertex(Vector3(-1,-1,1))
	imgeo.add_vertex(Vector3(-1,-1,-1))
	imgeo.end()

func set_color(value):
	outline_material.set_shader_param("color", value)
	solid_material.set_shader_param("color", value * Color(1,1,1,0.25))
	color = value

func read(file: File):
	transform.origin = RevoltStruct.ReadVector3(file)
	transform.basis = RevoltStruct.ReadBasis(file)
	var scale = RevoltStruct.ReadVector3(file)
	transform.basis.x *= scale.x
	transform.basis.y *= scale.y
	transform.basis.z *= scale.z

func write(file: File):
	RevoltStruct.WriteVector3(transform.origin, file)
	RevoltStruct.WriteBasis(transform.basis, file)
	RevoltStruct.WriteVector3(Vector3(transform.basis.x.length(), transform.basis.y.length(), transform.basis.z.length()), file)