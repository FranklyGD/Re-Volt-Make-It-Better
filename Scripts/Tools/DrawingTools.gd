class_name DrawingTools

static func dashed_line(imgeo: ImmediateGeometry, from: Vector3, to: Vector3, dash_length: float):
	var dashes = max(floor(from.distance_to(to) / dash_length), 1) * 2 - 1
	for i in range(dashes + 1):
		imgeo.add_vertex(lerp(from, to, float(i) / dashes))

static func arrow(imgeo: ImmediateGeometry, position: Vector3, direction: Vector3, facing: Vector3, size: float = 1):
	var horiz = direction.cross(facing).normalized() * size
	direction = direction.normalized() * size
	imgeo.add_vertex(position - direction - horiz / 2)
	imgeo.add_vertex(position - direction + horiz / 2)
	imgeo.add_vertex(position)