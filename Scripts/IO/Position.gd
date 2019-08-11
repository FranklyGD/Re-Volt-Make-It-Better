extends Spatial
class_name Position

const INVALID_LINK = 4294967295
const MAX_LINKS = 4
const MAX_NODES = 1024

var start = 0

class PositionNode:
	var position = Vector3()
	var links = []

	func _init(file: File = null):
		if file:
			read(file)

	func read(file: File):
		# Get Position
		position = RevoltStruct.ReadVector3(file)

		# Skip Distance to Finish
		file.seek(file.get_position() + 4)

		# Skip Previous Links
		file.seek(file.get_position() + 16)

		# Get Next Links
		for i in range(MAX_LINKS):
			var link = file.get_32()
			if link != INVALID_LINK:
				links.append(link)
	
	func write(file: File, index: int):
		# Write Position
		RevoltStruct.WriteVector3(position, file)
		
		file.seek(file.get_position() + 20)
		
		# Write Next Links
		for i in range(MAX_LINKS):
			if i < links.size():
				file.store_32(links[i])
			else:
				file.store_32(INVALID_LINK)

		var cursor = file.get_position()
		
		# Write Previous Links
		for link in links:
			file.seek(link * 0x30 + 0x1C)
			for l in range(MAX_LINKS):
				if file.get_32() == INVALID_LINK:
					file.seek(file.get_position() - 4)
					file.store_32(index)
					break
				
		file.seek(cursor)

var nodes = []

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

var closest_node_index = -1
var closest_node : PositionNode setget , get_closest_node
func get_closest_node():
	return null if closest_node_index == -1 else nodes[closest_node_index]
var is_over = false

var preselected_node_index = -1 # Also the held down node
var preselected_node : PositionNode setget , get_preselected_node
func get_preselected_node():
	return null if preselected_node_index == -1 else nodes[preselected_node_index]

var selected_node_index = -1
var selected_node : PositionNode setget , get_selected_node
func get_selected_node():
	return null if selected_node_index == -1 else nodes[selected_node_index]

var closest_split = {"node": -1, "link": -1, "t": 0.5, "position": Vector3.ZERO}

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
	
	for node in nodes:
		for i in range(node.links.size()):
			var link = node.links[i]
			if i >= MAX_LINKS:
				imgeo.set_color(Color.orange)
				imgeo_dashed.set_color(Color.white)
			else:
				imgeo.set_color(Color.white)
				imgeo_dashed.set_color(Color.white)

			imgeo.add_vertex(node.position)
			imgeo.add_vertex(nodes[link].position)
			
			DrawingTools.dashed_line(imgeo_dashed, node.position, nodes[link].position, 1)

	imgeo.end()
	imgeo_dashed.end()

	imgeo_dashed.begin(Mesh.PRIMITIVE_TRIANGLES)

	var view_pos = owner.camera.transform.origin

	if editable and selected_node_index != -1:
		var node = nodes[selected_node_index]
		imgeo_dashed.set_color(Color.yellow)

		var t = float(OS.get_ticks_msec()) / 250
		DrawingTools.arrow(imgeo_dashed, node.position + Vector3.UP * (sin(t) / 2 + 0.5), Vector3.DOWN, node.position - view_pos)
		DrawingTools.arrow(imgeo_dashed, node.position + Vector3.DOWN * (sin(t) / 2 + 0.5), Vector3.UP, node.position - view_pos)

	imgeo_dashed.set_color(Color.white)
	# Draw arrows to distiguish direction
	for i in range(nodes.size()):
		var node = nodes[i]
		for link in node.links:
			var other_node = nodes[link]
			
			var pos = lerp(node.position, other_node.position, 0.5)
			DrawingTools.arrow(imgeo_dashed, pos, other_node.position - node.position, pos - view_pos, 0.5)
				
	imgeo_dashed.end()

	imgeo.begin(Mesh.PRIMITIVE_POINTS)

	for node_index in range(nodes.size()):
		if node_index == closest_node_index:
			continue
		imgeo.set_color(Color.red if node_index == closest_node_index else Color.white)
		imgeo.add_vertex(nodes[node_index].position)
		
	imgeo.end()

func _unhandled_input(event):
	if event is InputEventMouseMotion: # Mouse Move
		if event.control:
			process_control()
		else:
			get_closest()
			process_handle()
			
		if preselected_node_index != -1 and event.button_mask & (BUTTON_LEFT | BUTTON_RIGHT):
			do_move_node(preselected_node_index, owner.cursor_3d.transform.origin)
		
	if event is InputEventMouseButton: # Mouse Buttons
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if event.control: # Create a new node at 3D mouse position
					preselected_node_index = nodes.size()
					if closest_split.node != -1:
						do_insert_node(closest_split.node, closest_split.link, closest_split.t)
					else:
						do_add_node(owner.cursor_3d.transform.origin)
				else:
					if is_over:
						preselected_node_index = closest_node_index
			else:
				if closest_node_index == preselected_node_index :
					do_select_node(closest_node_index)
				preselected_node_index = -1

		if event.button_index == BUTTON_RIGHT:
			if event.pressed:
				if event.control:
					closest_node_index = nodes.size()
					do_add_node(owner.cursor_3d.transform.origin)
				
				preselected_node_index = closest_node_index
				if preselected_node_index != -1:
					get_tree().set_input_as_handled()
			else:
				if selected_node_index != -1 and preselected_node_index != -1 and preselected_node_index == closest_node_index:
					do_change_link(selected_node_index, closest_node_index)
				
				if (event.alt or event.control) and preselected_node_index != -1 and preselected_node_index == closest_node_index:
					do_select_node(preselected_node_index)
				preselected_node_index = -1

	if event is InputEventKey:
		if event.scancode == KEY_CONTROL: # Hold for creation
			if event.pressed:
				surface_handle.visible = true
				process_control()
			else:
				closest_split.node = -1
				get_closest()
				process_handle()

		if event.scancode == KEY_DELETE: # Node deletion
			if event.pressed:
				do_remove_node(selected_node_index)
				get_closest()
				process_handle()

func read(file: File):
	var length = file.get_32()
	start = file.get_32()
	var distance = file.get_real() / 100

	for i in range(length):
		nodes.append(PositionNode.new(file))

func write(file: File):
	var length = nodes.size()
	file.store_32(length)
	file.store_32(start)
	
	file.seek(file.get_position() + 4)
	
	# Prewrite Previous Links
	for i in range(length):
		file.seek(i * 0x30 + 0x1C)
		for l in range(MAX_LINKS):
			file.store_32(INVALID_LINK)
	
	file.seek(12)
	
	for i in range(length):
		nodes[i].write(file, i)

func get_closest():
	var cursor_position = owner.cursor_3d.transform.origin
	var closest = -1
	var closest_distance = 1 # Max Range
	
	for node_index in range(nodes.size()):
		var node = nodes[node_index]
		var distance = cursor_position.distance_to(node.position)
		if distance < closest_distance:
			closest_distance = distance
			closest = node_index
			
	is_over = closest_distance < 0.5
	closest_node_index = closest

func get_closest_split():
	var cursor_position = owner.cursor_3d.transform.origin
	var selected_node = self.selected_node
	var closest = {"node": selected_node_index if selected_node_index != -1 and selected_node.links.size() > 0 else -1, "link": -1, "t": 0.5, "position": Vector3.ZERO}
	if not is_instance_valid(selected_node):
		is_over = false
		return closest
		
	var closest_distance = 1 # Max range
	
	# Next Links
	for i in range(selected_node.links.size()):
		var link = selected_node.links[i]
		var other_node = nodes[link]
	
		var t = clamp(MathTools.nearest_point_on_segment(selected_node.position, other_node.position, cursor_position), 0, 1)
		var position = lerp(selected_node.position, other_node.position, t)
		var distance = cursor_position.distance_to(position)
		if distance < closest_distance:
			closest_distance = distance
			closest.link = i
			closest.t = t
			closest.position = position
	
	# Previous Links
	for n in range(nodes.size()):
		var node = nodes[n]
		for i in range(node.links.size()):
			var link = node.links[i]
			if link != selected_node_index:
				continue
			
			var t = clamp(MathTools.nearest_point_on_segment(node.position, selected_node.position, cursor_position), 0, 1)
			var position = lerp(node.position, selected_node.position, t)
			var distance = cursor_position.distance_to(position)
			if distance < closest_distance:
				closest_distance = distance
				closest.node = n
				closest.link = i
				closest.t = t
				closest.position = position
		
	closest_split = closest

func get_previous(node_index) -> Array:
	var prev = []
	for s in range(nodes.size()):
		var node = nodes[s]
		for link in node.links:
			if link == node_index:
				prev.append(s)
	return prev

func process_handle():
	if closest_node_index != -1:
		var node = nodes[closest_node_index]

		var from = owner.camera.transform.origin
		var to = from + (self.closest_node.position - from) * 1.1
		
		var result = owner.world_space.intersect_ray(from, to, owner.trackZoneData.zones if owner.trackZoneData else [])
		
		surface_handle.transform.basis.y = result.get("normal", Vector3.UP)
		surface_handle.transform.basis.z = Vector3.RIGHT.cross(surface_handle.transform.basis.y).normalized()
		surface_handle.transform.basis.x = surface_handle.transform.basis.z.cross(surface_handle.transform.basis.y).normalized()
		surface_handle.transform.origin = result.get("position", self.closest_node.position) + result.get("normal", Vector3.UP) * 0.001
		surface_handle.visible = true
	else:
		surface_handle.visible = false

	if closest_node_index == selected_node_index:
		surface_handle.color = Color(1,1,0)
	else:
		surface_handle.color = Color(1,1,1)

func process_control():
	get_closest_split()
	if closest_split.node != -1:
		surface_handle.transform.origin = closest_split.position
	else:
		surface_handle.transform.origin = owner.cursor_3d.transform.origin

func select_node(node_index: int):
	selected_node_index = node_index

func do_select_node(node_index: int):
	owner.undo_redo.create_action("Select Node")
	owner.undo_redo.add_do_method(self, "select_node", node_index)
	owner.undo_redo.add_undo_method(self, "select_node", selected_node_index)
	owner.undo_redo.commit_action()

func move_node(node_index: int,  position: Vector3):
	var node = nodes[node_index]
	node.position = position

func do_move_node(node_index: int, position: Vector3): # Currently a lossy method
	owner.undo_redo.create_action("Move Node", UndoRedo.MERGE_ENDS)
	owner.undo_redo.add_do_method(self, "move_node", node_index, position)
	owner.undo_redo.add_undo_method(self, "move_node", node_index, position)
	owner.undo_redo.commit_action()

func add_node(position: Vector3 = Vector3.ZERO, i: int = -1):
	var new_node = PositionNode.new()
	new_node.position = position
	if i == -1:
		nodes.append(new_node)
	else:
		for node in nodes:
			for l in range(node.links.size()):
				if node.links[l] >= i:
					node.links[l] += 1;
		nodes.insert(i, new_node)

func do_add_node(position: Vector3 = Vector3.ZERO):
	owner.undo_redo.create_action("Add Node")
	owner.undo_redo.add_do_method(self, "add_node", position)
	owner.undo_redo.add_undo_method(self, "remove_node", nodes.size())
	owner.undo_redo.commit_action()

func insert_node(node_index: int, link_index: int, t: float = 0.5):
	var node = nodes[node_index]
	var other_node_index = node.links[link_index]
	var other_node = nodes[other_node_index]
	
	var new_node_index = nodes.size()
	add_node(lerp(node.position, other_node.position, t))
	var new_node = nodes[new_node_index]
	
	node.links[link_index] = new_node_index
	new_node.links.append(other_node_index)

func do_insert_node(node_index: int, link_index: int, t: float = 0.5):
	owner.undo_redo.create_action("Insert Node")
	owner.undo_redo.add_do_method(self, "insert_node", node_index, link_index, t)
	owner.undo_redo.add_undo_method(self, "remove_node", nodes.size())
	owner.undo_redo.commit_action()

func remove_node(node_index: int):
	if node_index != INVALID_LINK and not self.selected_node:
		return
	
	# Transfer links to the previous node
	for previous_node_index in get_previous(node_index):
		var previous_node = nodes[previous_node_index]
		var links = nodes[previous_node_index].links
		for i in range(links.size()):
			if node_index == links[i]:
				links.remove(i)
				var transfer_links = nodes[node_index].links
				previous_node.links += transfer_links
				break

	nodes.remove(node_index)

	# Shift all the links down
	for node in nodes:
		for i in range(node.links.size()):
			if node.links[i] > node_index:
				node.links[i] -= 1
				
	if selected_node_index == node_index:
		selected_node_index = -1
	closest_node_index = -1

func do_remove_node(node_index: int):
	owner.undo_redo.create_action("Remove Node")
	owner.undo_redo.add_do_method(self, "remove_node", node_index)
	owner.undo_redo.add_undo_method(self, "add_node", nodes[node_index].position, node_index)
	
	for link in nodes[node_index].links:
		owner.undo_redo.add_undo_method(self, "change_link", node_index, link)
	var previous_nodes = get_previous(node_index)
	for	previous_node_index in previous_nodes:
		owner.undo_redo.add_undo_method(self, "change_link", previous_node_index, node_index)
		for prev_link in nodes[previous_node_index].links:
			for link in nodes[node_index].links:
				if prev_link != link:
					owner.undo_redo.add_undo_method(self, "change_link", previous_node_index, link)
	
	owner.undo_redo.commit_action()

func change_link(from: int, to: int):
	# First pass remove link
	var to_node = nodes[to]
	for i in range(to_node.links.size()):
		if to_node.links[i] == from:
			remove_link(to, from)
			return

	# Second pass remove link
	var from_node = nodes[from]
	var from_link_count = from_node.links.size()
	for i in range(from_link_count):
		if from_node.links[i] == to:
			remove_link(from, to)
			return
	
	# Third pass add link
	add_link(from, to)

func do_change_link(from: int, to: int):
	owner.undo_redo.create_action("Change Link")
	owner.undo_redo.add_do_method(self, "change_link", from, to)
	owner.undo_redo.add_undo_method(self, "change_link", from, to)
	owner.undo_redo.commit_action()

func add_link(from: int, to: int):
	# Prevent accidentally linking to self
	if from == to:
		return

	var links = nodes[from].links
	if links.size() < MAX_LINKS:
		links.append(to)

func remove_link(from: int, to: int):
	var links = nodes[from].links

	for i in range(links.size()):
		if links[i] == to:
			links.remove(i)
			break