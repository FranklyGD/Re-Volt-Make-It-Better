extends Spatial
class_name TrackZone

const color_order = [
	Color.red,
	Color.green,
	Color.blue,
	Color.yellow,
	Color.magenta,
	Color.cyan,
]

class TZone extends Zone:
	var order setget order_set
	func order_set(value):
		order = value
		self.color = color_order[value % color_order.size()]
	
	func read(file: File):
		self.order = file.get_32()
		.read(file)
	
	func write(file: File):
		file.store_32(order)
		.write(file)

var zones = []

# Editor
var viewable: bool = true setget set_viewable
func set_viewable(value):
	viewable = value
	visible = value
	set_process(value)
	if value and editable:
		set_process_unhandled_input(true)
		set_process_unhandled_key_input(true)
		set_blocking(true)
	else:
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)
		set_blocking(false)

var editable: bool = true setget set_editable
func set_editable(value):
	editable = value
	if value and viewable:
		set_process_unhandled_input(true)
		set_process_unhandled_key_input(true)
		set_blocking(true)
	else:
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)
		set_blocking(false)

var closest_zone_index = -1;
var preselected_zone_index = -1;
var selected_zone_index = -1;

func _init(file_path: String):
	var file = File.new()
	file.open(file_path, File.READ)
	read(file)

func _ready():
	set_owner(get_node("/root/Re-Volt Editor"))	
	self.editable = editable

func _input(event):
	if event is InputEventMouseMotion:
		get_closest()
		print(closest_zone_index)

func read(file: File):
	var length = file.get_32()
	for i in range(length):
		var zone = TZone.new()
		zone.read(file)
		add_child(zone)
		zones.append(zone)

func write(file: File):
	var length = zones.size()
	file.store_32(length)
	for i in range(length):
		zones[i].write(file)

func set_blocking(value: bool):
	for zone in zones:
		zone.is_zone_blocking = value

func get_closest():
	var closest_distance = 1.01
	var closest = -1
	for zone_index in range(zones.size()):
		var zone = zones[zone_index]
		var local_position = zone.transform.xform_inv(owner.cursor_3d.transform.origin)
		var distance = max(
			abs(MathTools.nearest_point_on_vector(zone.transform.origin, zone.transform.basis.x, owner.cursor_3d.transform.origin)),
			max(abs(MathTools.nearest_point_on_vector(zone.transform.origin, zone.transform.basis.y, owner.cursor_3d.transform.origin)),
			abs(MathTools.nearest_point_on_vector(zone.transform.origin, zone.transform.basis.z, owner.cursor_3d.transform.origin)))
		)
		if distance < closest_distance:
			closest_distance = distance
			closest = zone_index
			
	closest_zone_index = closest