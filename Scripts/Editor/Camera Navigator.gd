extends Camera

var mouse_lock = false
var mouse_pos = Vector2.ZERO
var speed = 0
var yaw = 0
var pitch = 0

onready var speed_disp = $"UI/Speed Control/Speed Display"
onready var speed_slider = $"UI/Speed Control/Speed Slider"
	
func _ready():
	speed = pow(2.0, speed_slider.value)

func _process(delta):
	var forwardness = 0
	var rightness = 0
	var upness = 0
	if Input.is_action_pressed("camnav_forward"):
		forwardness += 1
	if Input.is_action_pressed("camnav_back"):
		forwardness -= 1
	if Input.is_action_pressed("camnav_right"):
		rightness += 1
	if Input.is_action_pressed("camnav_left"):
		rightness -= 1
	if Input.is_action_pressed("camnav_up"):
		upness += 1
	if Input.is_action_pressed("camnav_down"):
		upness -= 1

	var movement_direction = transform.basis.x * rightness - transform.basis.z * forwardness + transform.basis.y * upness
	transform.origin += movement_direction * delta * speed
	if movement_direction != Vector3.ZERO:
		process_3d_cursor(mouse_pos)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_RIGHT:
		mouse_lock = event.pressed
		if mouse_lock:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED | Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(0)
			
	if event is InputEventMouseMotion:
		if mouse_lock and Input.is_mouse_button_pressed(2):
			yaw -= event.relative.x / 300
			pitch -= event.relative.y / 300
			pitch = clamp(pitch, -PI/2, PI/2)
			transform.basis = Basis(Vector3(0,1,0), yaw) * Basis(Vector3(1,0,0), pitch)
		
		process_3d_cursor(event.position)
		mouse_pos = event.position
		
	if event is InputEventMouseButton and (event.button_index == BUTTON_WHEEL_UP or event.button_index == BUTTON_WHEEL_DOWN):
		if event.button_index == BUTTON_WHEEL_UP:
			speed_slider.value += 0.25
		elif event.button_index == BUTTON_WHEEL_DOWN:
			speed_slider.value -= 0.25

func _on_speed_slider_value_changed(value):
	speed = pow(2.0, value)
	speed_disp.text = "%.2fx" % speed

func process_3d_cursor(position: Vector2):
	var distance = far
	var from = project_ray_origin(position)
	var ray = project_ray_normal(position)
	while distance > 0:
		var to = from + ray * distance
		
		var result = owner.world_space.intersect_ray(from, to, owner.trackZoneData.zones if owner.trackZoneData else [])
		if result.size() > 0:
			if result.normal.dot(ray) > 0: # Re-cast if this is a back face
				distance -= result.normal.distance_to(result.position)
				from = result.position
				continue
			owner.cursor_3d.transform.origin = result.position
			break
		else:
			break