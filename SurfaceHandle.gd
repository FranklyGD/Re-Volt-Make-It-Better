extends ImmediateGeometry
class_name SurfaceHandle

var color := Color.white setget _set_color
func _set_color(value):
	color = value
	draw()

func _init():
	material_override = ShaderMaterial.new()
	material_override.shader = load("res://Handle.shader")
	draw()

func draw():
	clear()
	
	begin(Mesh.PRIMITIVE_LINE_LOOP)
	set_color(color)
	
	add_vertex(Vector3(0.5,0,0))
	add_vertex(Vector3(0.3535,0,0.3535))
	add_vertex(Vector3(0,0,0.5))
	add_vertex(Vector3(-0.3535,0,0.3535))
	add_vertex(Vector3(-0.5,0,0))
	add_vertex(Vector3(-0.3535,0,-0.3535))
	add_vertex(Vector3(0,0,-0.5))
	add_vertex(Vector3(0.3535,0,-0.3535))
	
	end()
	
	begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	set_color(color * Color(1,1,1,0.25))
	
	add_vertex(Vector3(0,0,0))
	
	add_vertex(Vector3(0.5,0,0))
	add_vertex(Vector3(0.3535,0,0.3535))
	add_vertex(Vector3(0,0,0.5))
	add_vertex(Vector3(-0.3535,0,0.3535))
	add_vertex(Vector3(-0.5,0,0))
	add_vertex(Vector3(-0.3535,0,-0.3535))
	add_vertex(Vector3(0,0,-0.5))
	add_vertex(Vector3(0.3535,0,-0.3535))
	add_vertex(Vector3(0.5,0,0))
	
	end()
