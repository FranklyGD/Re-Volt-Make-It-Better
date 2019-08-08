extends StaticBody
class_name TrackWorld

var mesh_renderer = MeshInstance.new()
var mesh_array = ArrayMesh.new()
var mesh_collider = CollisionShape.new()

var materials = {}
var texture_base_name : String

const NULL_TEXTURE_INDEX = 65535

const POLY_QUAD = 0x1
const POLY_SEMI_TRANSPARENT = 0x100
const POLY_ADDITIVE = 0x100000000

func _init(folder_path: String):
	add_child(mesh_renderer)
	add_child(mesh_collider)
	mesh_collider.shape = ConcavePolygonShape.new()
	
	# Split track name from path
	texture_base_name = folder_path.get_file()
	var file = File.new()
	file.open("%s/%s.w" % [folder_path, texture_base_name], File.READ)
	read_w(file)
	
	mesh_collider.shape.set_faces(mesh_array.get_faces())
	
	for texture_index in materials:
		if texture_index != NULL_TEXTURE_INDEX:
			var texture_file_path = "%s/%s.bmp" % [folder_path, texture_base_name + char(65 + 32 + texture_index)]
			var image = Image.new()
			var image_texture = ImageTexture.new()
			image.load(texture_file_path)
			image_texture.create_from_image(image)
			materials[texture_index].albedo_texture = image_texture

func read_w(file: File):
	var length = file.get_32()
	for i in range(length):
		read_mesh(file)
	mesh_renderer.mesh = mesh_array

func read_mesh(file: File):
	file.seek(file.get_position() + 40)

	var polygon_length = file.get_16()
	var vertex_length = file.get_16()

	var polygons = []
	var vertices = []

	for i in range(polygon_length):
		polygons.append(read_polygon(file))
	for i in range(vertex_length):
		vertices.append(read_vertex(file))
	
	var sub_meshs = {}
	for polygon in polygons:
		var sub_mesh = sub_meshs.get(polygon.texture_index)
		if not sub_mesh:
			sub_mesh = []
			sub_meshs[polygon.texture_index] = sub_mesh
		sub_mesh.append(polygon)

	var mesh_gen = SurfaceTool.new()
	for texture_index in sub_meshs:
		var submesh = sub_meshs[texture_index]
		
		var material = materials.get(texture_index)
		if not material:
			material = SpatialMaterial.new()
			material.flags_unshaded = true
			material.vertex_color_use_as_albedo = true

			materials[texture_index] = material
	
		mesh_gen.clear()
		mesh_gen.begin(Mesh.PRIMITIVE_TRIANGLES)
		mesh_gen.set_material(material)
		
		for polygon in submesh:
			for i in [0,1,2]:
				mesh_gen.add_color(polygon.colors[i])
				mesh_gen.add_uv(polygon.uvs[i])
				
				var vertex_index = polygon.vertex_indices[i]
				mesh_gen.add_normal(vertices[vertex_index].normal)
				mesh_gen.add_vertex(vertices[vertex_index].position)
	
			if polygon.flags & POLY_QUAD:
				for i in [0,2,3]:
					mesh_gen.add_color(polygon.colors[i])
					mesh_gen.add_uv(polygon.uvs[i])
					
					var vertex_index = polygon.vertex_indices[i]
					mesh_gen.add_normal(vertices[vertex_index].normal)
					mesh_gen.add_vertex(vertices[vertex_index].position)
	
		mesh_gen.index()
		mesh_array = mesh_gen.commit(mesh_array)

func read_polygon(file: File):
	var flags = file.get_16()
	var texture = file.get_16()

	var vertices = PoolIntArray()
	for i in range(4):
		vertices.append(file.get_16())

	var colors = PoolColorArray()
	for i in range(4):
		var p = file.get_position()
		colors.append(RevoltStruct.ReadColor(file))

	var uvs = PoolVector2Array()
	for i in range(4):
		uvs.append(RevoltStruct.ReadVector2(file))

	var polygon = {
		"texture_index": texture,
		"vertex_indices": vertices,
		"colors": colors,
		"uvs": uvs,
		"flags": flags
	}

	return polygon

func read_vertex(file: File):
	var vertex = {
		"position": RevoltStruct.ReadVector3(file),
		"normal": RevoltStruct.ReadVector3(file, 1)
	}

	return vertex