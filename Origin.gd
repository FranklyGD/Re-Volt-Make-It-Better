tool
extends ImmediateGeometry

# Called when the node enters the scene tree for the first time.
func _ready():
	transform.origin = Vector3.ZERO

func _process(delta):
	clear()
	begin(Mesh.PRIMITIVE_LINES)
	set_color(Color.red)
	add_vertex(Vector3(1,0,0))
	set_color(Color.white)
	add_vertex(Vector3(0,0,0))
	add_vertex(Vector3(0,0,0))
	set_color(Color.red)
	add_vertex(Vector3(-1,0,0))

	set_color(Color.green)
	add_vertex(Vector3(0,1,0))
	set_color(Color.white)
	add_vertex(Vector3(0,0,0))
	add_vertex(Vector3(0,0,0))
	set_color(Color.green)
	add_vertex(Vector3(0,-1,0))

	set_color(Color.blue)
	add_vertex(Vector3(0,0,1))
	set_color(Color.white)
	add_vertex(Vector3(0,0,0))
	add_vertex(Vector3(0,0,0))
	set_color(Color.blue)
	add_vertex(Vector3(0,0,-1))
	end()

	pass
