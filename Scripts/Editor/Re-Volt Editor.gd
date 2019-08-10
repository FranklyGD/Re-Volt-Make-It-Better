extends Spatial

signal on_load

var dir = Directory.new()
var file = File.new()

const POS_EXTENSION = "pan"
const AI_EXTENSION = "fan"
const TRACK_ZONE_EXTENSION = "taz"
const TRACK_WORLD_EXTENSION = "w"
const TRACK_INFO_EXTENSION = "inf"

const path_pattern = "%s/%s.%s"
var data_name : String

var trackData : TrackInfo
var trackWorldData : TrackWorld
var positionData : Position
var aiData : AI
var trackZoneData : TrackZone

#var undo = UndoRedo.new()

onready var world_space = get_world().direct_space_state

onready var camera = $Camera
var cursor_3d = ImmediateGeometry.new()
var undo_stack = []

func _ready():
	var material = SpatialMaterial.new()
	material.flags_unshaded = true
	cursor_3d.material_override = material
	
	add_child(cursor_3d)
	cursor_3d.name = "3D Cursor"

	cursor_3d.clear()
	
	cursor_3d.begin(Mesh.PRIMITIVE_LINES)
	
	cursor_3d.add_vertex(Vector3.UP)
	cursor_3d.add_vertex(Vector3.DOWN)
	
	cursor_3d.add_vertex(Vector3.LEFT)
	cursor_3d.add_vertex(Vector3.RIGHT)
	
	cursor_3d.add_vertex(Vector3.FORWARD)
	cursor_3d.add_vertex(Vector3.BACK)
	
	cursor_3d.end()

func load_track(folder_path: String):
	# Split track name from path
	dir.open(folder_path)
	folder_path = dir.get_current_dir()
	data_name = folder_path.get_file()
	
	var file = File.new()
	
	var track_world_path = path_pattern % [folder_path, data_name, TRACK_WORLD_EXTENSION]
	if not file.file_exists(track_world_path):
		return
	
	OS.set_window_title("Re-Volt - Make It Better: %s" % data_name) 
	
	# Clear area if the file is valid
	if is_instance_valid(trackWorldData):
		trackWorldData.queue_free()
	if is_instance_valid(trackData):
		trackData.queue_free()
	if is_instance_valid(positionData):
		positionData.queue_free()
	if is_instance_valid(aiData):
		aiData.queue_free()
	if is_instance_valid(trackZoneData):
		trackZoneData.queue_free()
	
	trackWorldData = TrackWorld.new(folder_path)
	add_child(trackWorldData)
	
	var info_path = path_pattern % [folder_path, data_name, TRACK_INFO_EXTENSION]
	if file.file_exists(info_path):
		trackData = TrackInfo.new(info_path)
		add_child(trackData)
		
		if trackData.track_name:
			OS.set_window_title("Re-Volt - Make It Better: %s" % trackData.track_name)
		
		camera.transform.origin = trackData.starting_position + Vector3.UP * 2
		camera.transform.basis = Basis(Vector3.DOWN, trackData.starting_rotation)
		camera.yaw = -trackData.starting_rotation
	
	var pos_path = path_pattern % [folder_path, data_name, POS_EXTENSION]
	if file.file_exists(pos_path):
		positionData = Position.new(pos_path)
		positionData.editable = false
		add_child(positionData)
	
	var ai_path = path_pattern % [folder_path, data_name, AI_EXTENSION]
	if file.file_exists(ai_path):
		aiData = AI.new(ai_path)
		aiData.editable = false
		add_child(aiData)
		
	var track_zone_path = path_pattern % [folder_path, data_name, TRACK_ZONE_EXTENSION]
	if file.file_exists(track_zone_path):
		trackZoneData = TrackZone.new(track_zone_path)
		trackZoneData.editable = false
		add_child(trackZoneData)
	
	emit_signal("on_load")

func save_data(data_node: Node, extension: String):
	if is_instance_valid(data_node):
		var folder_path = dir.get_current_dir()
	
		var data = File.new()
		data.open(path_pattern % [folder_path, data_name + "test", extension], File.WRITE_READ)
		data_node.write(data)
		data.close()

func save_pos():
	save_data(positionData, POS_EXTENSION)

func save_ai():
	save_data(aiData, AI_EXTENSION)

func save_tz():
	pass#save_data(trackZoneData, TRACK_ZONE_EXTENSION)