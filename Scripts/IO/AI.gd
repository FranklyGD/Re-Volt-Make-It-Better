extends Spatial
class_name AI

const INVALID_LINK = 4294967295
const MAX_LINKS = 2

class AISegment:
	class AINode:
		var speed = 30
		var position = Vector3()

		func _init(file: File = null):
			if file:
				read(file)

		func read(file: File):
			# Get Speed
			speed = file.get_32()

			# Get Position
			position = RevoltStruct.ReadVector3(file)
		
		func write(file: File):
			# Write Speed
			file.store_32(speed)

			# Write Position
			RevoltStruct.WriteVector3(position, file)

	var priority = 0
	var is_start = false
	var walls = [false,false]

	var racing_line = 0.5
	var overtaking_line = 0.5
	var racing_speed = 30 # Unused in game
	var center_speed = 30 # Unused in game

	var links = []

	var left = AINode.new()
	var right = AINode.new()

	func _init(file: File = null):
		if file:
			read(file)

	func read(file: File):
		# Priority Type
		priority = file.get_8()
		# Is this the starting line?
		is_start = file.get_8() > 0

		# Walls
		var wall_flags = file.get_8()
		walls[0] = wall_flags & 1 > 0
		walls[1] = wall_flags & 2 > 0

		# Walls 2.0 (Skip)
		file.seek(file.get_position() + 1)

		# Get Racing Line Position on Segment [0 to 1]
		racing_line = file.get_real()

		# Skip Distance
		file.seek(file.get_position() + 4)

		# Get Overtaking Line Position on Segment [0 to 1]
		overtaking_line = file.get_real()

		file.seek(file.get_position() + 4)

		# Get Speeds
		racing_speed = file.get_32()
		center_speed = file.get_32()

		# Skip
		file.seek(file.get_position() + 8)

		# Get Next Links
		for i in range(MAX_LINKS):
			var link = file.get_32()
			if link != INVALID_LINK:
				links.append(link)

		# Get Endpoint Information
		right.read(file)
		left.read(file)

	func write(file: File, index: int):
		# Priority Type
		file.store_8(priority)
		# Is this the starting line?
		file.store_8(1 if is_start else 0)

		# Walls
		var wall_flags = 0
		if walls[0]:
			wall_flags += 1
		if walls[1]:
			wall_flags += 2
		file.store_8(wall_flags)

		# Walls 2.0
		file.store_8(wall_flags)

		# Racing Line Position on Segment
		file.store_real(racing_line)

		# Skip Distance
		file.seek(file.get_position() + 4)

		# Overtaking Line Position on Segment [0 to 1]
		file.store_real(overtaking_line)

		file.seek(file.get_position() + 4)

		# Get Speeds
		file.store_32(racing_speed)
		file.store_32(center_speed)

		# Skip
		file.seek(file.get_position() + 8)

		# Write Next Links
		for i in range(MAX_LINKS):
			if i < links.size():
				file.store_32(links[i])
			else:
				file.store_32(INVALID_LINK)

		var cursor = file.get_position()

		# Write Previous Links
		for link in links:
			file.seek(link * 0x4C + 0x20)
			for l in range(MAX_LINKS):
				if file.get_32() == INVALID_LINK:
					file.seek(file.get_position() - 4)
					file.store_32(index)
					break
				
		file.seek(cursor)

		# Write Endpoint Information
		right.write(file)
		left.write(file)

var segments = []

# Editor
var imgeo = ImmediateGeometry.new()
var imgeo_dashed = ImmediateGeometry.new()

var viewable: bool = true setget set_viewable
func set_viewable(value):
	viewable = value
	visible = value
	set_process(value)
	if value and editable:
		set_process_unhandled_input(true)
		set_process_unhandled_key_input(true)
	else:
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)

var editable: bool = true setget set_editable
func set_editable(value):
	editable = value
	surface_handle.visible = value
	if value and viewable:
		set_process_unhandled_input(true)
		set_process_unhandled_key_input(true)
	else:
		set_process_unhandled_input(false)
		set_process_unhandled_key_input(false)

enum {
	SIDE_LEFT,
	SIDE_RIGHT,
	SIDE_RACING,
	SIDE_OVERTAKING
}

var closest_index = {"segment": -1, "side": SIDE_LEFT}
var is_over = false

var preselected_index = {"segment": -1, "side": SIDE_LEFT} # Also the held down node

var selected_index = {"segment": -1, "side": SIDE_LEFT}
var selected_segment : AISegment setget , get_selected_segment
func get_selected_segment():
	return null if selected_index.segment == -1 else segments[selected_index.segment]

var closest_node : AISegment.AINode setget , get_closest_node
func get_closest_node():
	var segment = segments[closest_index.segment]
	return null if not segment or closest_index.side == -1 else (segment.left if closest_index.side == SIDE_LEFT else segment.right)

var closest_split = {"segment": -1, "link": -1, "side": SIDE_LEFT, "t": 0.5, "position": Vector3.ZERO}

var surface_handle = SurfaceHandle.new()

func _init(file_path: String):
	add_child(surface_handle)
	add_child(imgeo)
	add_child(imgeo_dashed)
	
	var material = ShaderMaterial.new()
	var dashed_material = ShaderMaterial.new()
	var shader = load("res://Handle.shader")
	material.shader = shader
	material.set_shader_param("fade", 0.5)
	dashed_material.shader = shader
	dashed_material.set_shader_param("offset", 0.5)
	dashed_material.set_shader_param("fade", 100)
	
	imgeo.material_override = material
	imgeo_dashed.material_override = dashed_material

	var file = File.new()
	file.open(file_path, File.READ)
	read(file)

func _ready():
	set_owner(get_node("/root/Re-Volt Editor"))
	self.editable = editable

func _process(delta):
	imgeo.clear()
	imgeo_dashed.clear()
	imgeo.begin(Mesh.PRIMITIVE_LINES)
	imgeo_dashed.begin(Mesh.PRIMITIVE_LINES)

	process_highlight()

	for i in range(segments.size()):
		var segment = segments[i]
		
		imgeo.set_color(Color.green)
		imgeo.add_vertex(segment.left.position)
		imgeo.add_vertex(segment.left.position + (segment.left.position - segment.right.position).normalized())
		imgeo.set_color(Color.red)
		imgeo.add_vertex(segment.right.position)
		imgeo.add_vertex(segment.right.position + (segment.right.position - segment.left.position).normalized())
		
		var racing_position = lerp(segment.left.position, segment.right.position, segment.racing_line)
		var overtaking_position = lerp(segment.left.position, segment.right.position, segment.overtaking_line)

		# Draw lines between segments that are linked
		for link in segment.links:
			var other_segment = segments[link]
			imgeo.set_color(Color.green)
			imgeo.add_vertex(segment.left.position)
			imgeo.add_vertex(other_segment.left.position)
			imgeo_dashed.set_color(Color.green)
			DrawingTools.dashed_line(imgeo_dashed, segment.left.position, other_segment.left.position, 2)
			
			imgeo.set_color(Color.red)
			imgeo.add_vertex(segment.right.position)
			imgeo.add_vertex(other_segment.right.position)
			imgeo_dashed.set_color(Color.red)
			DrawingTools.dashed_line(imgeo_dashed, segment.right.position, other_segment.right.position, 2)

			var other_racing_position = lerp(other_segment.left.position, other_segment.right.position, other_segment.racing_line)
			imgeo.set_color(Color.white)
			imgeo.add_vertex(racing_position)
			imgeo.add_vertex(other_racing_position)
			imgeo_dashed.set_color(Color.white)
			DrawingTools.dashed_line(imgeo_dashed, racing_position, other_racing_position, 2)

			var other_overtaking_position = lerp(other_segment.left.position, other_segment.right.position, other_segment.overtaking_line)
			imgeo.set_color(Color.magenta)
			imgeo.add_vertex(overtaking_position)
			imgeo.add_vertex(other_overtaking_position)
			imgeo_dashed.set_color(Color.magenta)
			DrawingTools.dashed_line(imgeo_dashed, overtaking_position, other_overtaking_position, 2)

	imgeo.end()
	imgeo_dashed.end()

	imgeo_dashed.begin(Mesh.PRIMITIVE_TRIANGLES)

	var view_pos = owner.camera.transform.origin

	if editable and selected_index.segment != -1:
		var segment = segments[selected_index.segment]
		var segment_ray = segment.right.position - segment.left.position
		imgeo_dashed.set_color(Color.yellow)
		DrawingTools.arrow(imgeo_dashed, segment.left.position - segment_ray.normalized() * (sin(float(OS.get_ticks_msec()) / 250) / 2 + 0.5), segment_ray, segment.left.position - view_pos)
		DrawingTools.arrow(imgeo_dashed, segment.right.position + segment_ray.normalized() * (sin(float(OS.get_ticks_msec()) / 250) / 2 + 0.5), -segment_ray, segment.right.position - view_pos)

	# Draw arrows to distiguish direction
	for i in range(segments.size()):
		var segment = segments[i]
		for link in segment.links:
			var other_segment = segments[link]
			
			var left_pos = lerp(segment.left.position, other_segment.left.position, 0.5)
			imgeo_dashed.set_color(Color.green)
			DrawingTools.arrow(imgeo_dashed, left_pos, other_segment.left.position - segment.left.position, left_pos - view_pos, 0.5)
			
			var right_pos = lerp(segment.right.position, other_segment.right.position, 0.5)
			imgeo_dashed.set_color(Color.red)
			DrawingTools.arrow(imgeo_dashed, right_pos, other_segment.right.position - segment.right.position, right_pos - view_pos, 0.5)
	
	imgeo_dashed.end()

	imgeo.begin(Mesh.PRIMITIVE_POINTS)
	for segment in segments:
		imgeo.set_color(Color.green)
		imgeo.add_vertex(segment.left.position)
		imgeo.set_color(Color.red)
		imgeo.add_vertex(segment.right.position)
	imgeo.end()

func _unhandled_input(event):
	if event is InputEventMouseMotion: # Mouse Move
		if event.control:
			process_control()
		else:
			get_closest()
			process_handle()
			
		if preselected_index.segment != -1:
			var segment = segments[preselected_index.segment]
			if preselected_index.side == SIDE_RACING:
				segment.racing_line = clamp(MathTools.nearest_point_on_segment(segment.left.position, segment.right.position, owner.cursor_3d.transform.origin), 0.001, 0.999)
			elif preselected_index.side == SIDE_OVERTAKING:
				segment.overtaking_line = clamp(MathTools.nearest_point_on_segment(segment.left.position, segment.right.position, owner.cursor_3d.transform.origin), 0.001, 0.999)
			else:
				if event.button_mask & (BUTTON_LEFT | BUTTON_RIGHT):
					var node = segment.left if preselected_index.side == SIDE_LEFT else segment.right
					node.position = owner.cursor_3d.transform.origin
		
	if event is InputEventMouseButton: # Mouse Buttons
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if event.control: # Create a new node at 3D mouse position
					closest_index.segment = segments.size() 
					if closest_split.segment != -1:
						closest_index.side = closest_split.side
						insert_segment(closest_split.segment, closest_split.link, closest_split.t)
					else:
						closest_index.side = SIDE_RIGHT
						add_segment(owner.cursor_3d.transform.origin)
					preselected_index = closest_index.duplicate()
				else:
					if is_over:
						preselected_index = closest_index.duplicate()
			else:
				if closest_index.segment == preselected_index.segment:
					select_node(preselected_index.segment, preselected_index.side)
				preselected_index.segment = -1

		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if event.control:
					closest_index.segment = segments.size() 
					closest_index.side = SIDE_RIGHT
					add_segment(owner.cursor_3d.transform.origin)

				preselected_index = closest_index.duplicate()
				if preselected_index.segment != -1:
					get_tree().set_input_as_handled()
			else:
				if selected_index.segment != -1 and get_segment_unpressed():
					change_link(selected_index.segment, preselected_index.segment)
				
				if (event.alt or event.control) and get_side_unpressed():
					select_node(preselected_index.segment, preselected_index.side)
				preselected_index.segment = -1

	if event is InputEventKey:
		if event.scancode == KEY_CONTROL: # Hold for creation
			if event.pressed:
				surface_handle.visible = true
				process_control()
			else:
				closest_split.segment = -1
				get_closest()
				process_handle()

		if event.scancode == KEY_ALT:
			get_closest()
			process_handle()

		if event.scancode == KEY_DELETE: # Node deletion
			if event.pressed:
				remove_segment(selected_index.segment)
				get_closest()
				process_handle()

func read(file: File):
	var length = file.get_16()
	var distance = file.get_16()

	for i in range(length):
		segments.append(AISegment.new(file))

func write(file: File):
	var length = segments.size()
	file.store_16(length)
	file.seek(file.get_position() + 2)

	# Prewrite Previous Links
	for i in range(length):
		file.seek(i * 0x4C + 0x20)
		for l in range(MAX_LINKS):
			file.store_32(INVALID_LINK)
	
	file.seek(4)

	for i in range(length):
		segments[i].write(file, i)

func get_closest():
	var cursor_position = owner.cursor_3d.transform.origin
	var closest = {"segment": -1, "side": SIDE_LEFT}
	var closest_distance = 1 # Max Range
	
	for segment_index in range(segments.size()):
		var segment = segments[segment_index]
		for node_side in [SIDE_LEFT, SIDE_RIGHT]:
			var node 
			if node_side == SIDE_LEFT:
				node = segment.left
			else:
				node = segment.right

			var distance = cursor_position.distance_to(node.position)
			if distance < closest_distance:
				closest_distance = distance
				closest.segment = segment_index
				closest.side = node_side
	
	if selected_index.segment != -1:
		var selected_segment = segments[selected_index.segment]
		var position = lerp(selected_segment.left.position, selected_segment.right.position, selected_segment.overtaking_line if Input.is_key_pressed(KEY_ALT) else selected_segment.racing_line)

		var distance = cursor_position.distance_to(position)
		if distance < closest_distance:
			closest_distance = distance
			closest.segment = selected_index.segment
			closest.side = SIDE_OVERTAKING if Input.is_key_pressed(KEY_ALT) else SIDE_RACING
				
	is_over = closest_distance < 0.5
	closest_index = closest

func get_closest_split():
	var cursor_position = owner.cursor_3d.transform.origin
	var closest = {"segment": -1, "link": -1, "t": 0.5, "side": SIDE_LEFT, "position": Vector3.ZERO}
	var selected_segment = self.selected_segment
	if not is_instance_valid(selected_segment):
		is_over = false
		return closest

	var closest_distance = 1 # Max range

	# Next Links
	for i in range(selected_segment.links.size()):
		var link = selected_segment.links[i]
		var other_segment = segments[link]
		
		# Left
		var t = clamp(MathTools.nearest_point_on_segment(selected_segment.left.position, other_segment.left.position, cursor_position), 0, 1)
		var position = lerp(selected_segment.left.position, other_segment.left.position, t)
		var distance = cursor_position.distance_to(position)
		if distance < closest_distance:
			closest_distance = distance
			closest.segment = selected_index.segment
			closest.link = i
			closest.t = t
			closest.side = SIDE_LEFT
			closest.position = position
		
		# Right
		t = clamp(MathTools.nearest_point_on_segment(selected_segment.right.position, other_segment.right.position, cursor_position), 0, 1)
		position = lerp(selected_segment.right.position, other_segment.right.position, t)
		distance = cursor_position.distance_to(position)
		if distance < closest_distance:
			closest_distance = distance
			closest.segment = selected_index.segment
			closest.link = i
			closest.t = t
			closest.side = SIDE_RIGHT
			closest.position = position
	
	# Previous Links
	for s in range(segments.size()):
		var segment = segments[s]
		for i in range(segment.links.size()):
			var link = segment.links[i]
			if link != selected_index.segment:
				continue
		
			# Left
			var t = clamp(MathTools.nearest_point_on_segment(segment.left.position, selected_segment.left.position, cursor_position), 0, 1)
			var position = lerp(segment.left.position, selected_segment.left.position, t)
			var distance = cursor_position.distance_to(position)
			if distance < closest_distance:
				closest_distance = distance
				closest.segment = s
				closest.link = i
				closest.t = t
				closest.side = SIDE_LEFT
				closest.position = position
			
			# Right
			t = clamp(MathTools.nearest_point_on_segment(segment.right.position, selected_segment.right.position, cursor_position), 0, 1)
			position = lerp(segment.right.position, selected_segment.right.position, t)
			distance = cursor_position.distance_to(position)
			if distance < closest_distance:
				closest_distance = distance
				closest.segment = s
				closest.link = i
				closest.t = t
				closest.side = SIDE_RIGHT
				closest.position = position
	
	closest_split = closest

func get_segment_unpressed():
	return preselected_index.segment != -1 and closest_index.segment == preselected_index.segment 

func get_side_unpressed():
	return get_segment_unpressed() and closest_index.side == preselected_index.side

func process_highlight():
	if closest_index.segment != -1:
		var segment = segments[closest_index.segment]
		imgeo.set_color(Color.green)
		imgeo.add_vertex(segment.left.position)
		imgeo.set_color(Color.red)
		imgeo.add_vertex(segment.right.position)
		
	if editable and selected_index.segment != -1:
		var segment = segments[selected_index.segment]
		imgeo.set_color(Color.yellow)
		DrawingTools.dashed_line(imgeo, segment.left.position, segment.right.position, 2)
	
	if closest_split.segment != -1:
		var segment = segments[closest_split.segment]
		var other_segment = segments[segment.links[closest_split.link]]
		imgeo.set_color(Color.gray)
		DrawingTools.dashed_line(imgeo, lerp(segment.left.position, other_segment.left.position, closest_split.t), lerp(segment.right.position, other_segment.right.position, closest_split.t), 2)


func process_handle():
	if closest_index.segment != -1 and closest_index.side != -1:
		var segment = segments[closest_index.segment]
		var position
		match closest_index.side:
			SIDE_LEFT:
				position = segment.left.position
			SIDE_RIGHT:
				position = segment.right.position
			SIDE_RACING:
				position = lerp(segment.left.position, segment.right.position, segment.racing_line)
			SIDE_OVERTAKING:
				position = lerp(segment.left.position, segment.right.position, segment.overtaking_line)
	
		var from = owner.camera.transform.origin
		var to = from + (position - from) * 1.1
		
		var result = owner.world_space.intersect_ray(from, to, owner.trackZoneData.zones if owner.trackZoneData else [])
		
		surface_handle.transform.basis.y = result.get("normal", Vector3.UP)
		surface_handle.transform.basis.z = Vector3.RIGHT.cross(surface_handle.transform.basis.y).normalized()
		surface_handle.transform.basis.x = surface_handle.transform.basis.z.cross(surface_handle.transform.basis.y).normalized()
		surface_handle.transform.origin = result.get("position", position) + result.get("normal", Vector3.UP) * 0.001
		surface_handle.visible = true
	else:
		surface_handle.visible = false

	if closest_index.segment == selected_index.segment and closest_index.side == selected_index.side and not Input.is_key_pressed(KEY_CONTROL):
		surface_handle.color = Color(1,1,0)
	else:
		surface_handle.color = Color(1,1,1)

func process_control():
	get_closest_split()
	if closest_split.segment != -1:
		surface_handle.transform.origin = closest_split.position
	else:
		surface_handle.transform.origin = owner.cursor_3d.transform.origin

func select_node(segment_index: int, side: int):
	selected_index.segment = segment_index
	selected_index.side = side

func add_segment(position: Vector3 = Vector3.ZERO):
	var new_segment = AISegment.new()
	new_segment.left.position = position
	new_segment.right.position = position
	segments.append(new_segment)

func insert_segment(segment_index: int, link_index: int, t: float = 0.5):
	var segment = segments[segment_index]
	var other_segment_index = segment.links[link_index]
	var other_segment = segments[other_segment_index]
	
	var new_segment_index = segments.size()
	add_segment()
	var new_segment = segments[new_segment_index]
	
	segment.links[link_index] = new_segment_index
	new_segment.links.append(other_segment_index)
	
	new_segment.left.position = lerp(segment.left.position, other_segment.left.position, t)
	new_segment.right.position = lerp(segment.right.position, other_segment.right.position, t)
	new_segment.racing_line = lerp(segment.racing_line, other_segment.racing_line, t)
	new_segment.overtaking_line = lerp(segment.overtaking_line, other_segment.overtaking_line, t)
	new_segment.walls = segment.walls.duplicate()

func remove_segment(segment_index: int):
	if segment_index != INVALID_LINK and not self.selected_segment:
		return
	
	# Transfer links to the previous segment
	for segment in segments:
		var links = segment.links
		for i in range(links.size()):
			if segment_index == links[i]:
				links.remove(i)
				var transfer_links = segments[segment_index].links
				segment.links += transfer_links
				break

	segments.remove(segment_index)

	# Shift all the links down
	for segment in segments:
		for i in range(segment.links.size()):
			if segment.links[i] > segment_index:
				segment.links[i] -= 1
	
	if selected_index.segment == segment_index:
		selected_index.segment = -1
	closest_index.segment = -1

func change_link(from: int, to: int):
	# First pass remove link
	var to_segment = segments[to]
	for i in range(to_segment.links.size()):
		if to_segment.links[i] == from:
			remove_link(to, from)
			return

	# Second pass remove link
	var from_segment = segments[from]
	var from_link_count = from_segment.links.size()
	for i in range(from_link_count):
		if from_segment.links[i] == to:
			remove_link(from, to)
			return
	
	# Third pass add link
	add_link(from, to)

func add_link(from: int, to: int):
	# Prevent accidentally linking to self
	if from == to:
		return

	var links = segments[from].links
	if links.size() < MAX_LINKS:
		links.append(to)

func remove_link(from: int, to: int):
	var links = segments[from].links

	for i in range(links.size()):
		if links[i] == to:
			links.remove(i)
			break