class_name MathTools

static func nearest_point_on_segment(a: Vector3, b: Vector3, p: Vector3) -> float:
	var s = b - a
	var v = a - p
	var ls = s.length_squared()
	return -(s.dot(v))/(ls) if ls > 0 else 0.5