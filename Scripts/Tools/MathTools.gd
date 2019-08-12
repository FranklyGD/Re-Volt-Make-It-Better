class_name MathTools

static func nearest_point_on_segment(a: Vector3, b: Vector3, p: Vector3) -> float:
	var s = b - a
	var u = a - p
	var ls = s.length_squared()
	return -(s.dot(u))/(ls) if ls > 0 else 0.5
	
static func nearest_point_on_vector(o: Vector3, v: Vector3, p: Vector3) -> float:
	var u = o - p
	var ls = v.length_squared()
	return -(v.dot(u))/(ls) if ls > 0 else 0.5