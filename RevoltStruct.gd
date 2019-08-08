class_name RevoltStruct

static func ReadVector3(file: File, scale: float = 100) -> Vector3:
	var v = Vector3(
		file.get_real() / scale,
		file.get_real() / -scale,
		file.get_real() / -scale
	)
	return v

static func WriteVector3(vector3: Vector3, file: File, scale: float = 100) -> void:
	file.store_real(vector3.x * scale)
	file.store_real(vector3.y * -scale)
	file.store_real(vector3.z * -scale)

static func ReadVector2(file: File) -> Vector2:
	var v = Vector2(
		file.get_real(),
		file.get_real()
	)
	return v

static func WriteVector2(vector2: Vector2, file: File) -> void:
	file.store_real(vector2.x)
	file.store_real(vector2.y)

static func ReadColor(file: File) -> Color:
	var c = Color()
	c.b = float(file.get_8()) / 255
	c.g = float(file.get_8()) / 255
	c.r = float(file.get_8()) / 255
	c.a = float(file.get_8()) / 255
	return c

static func WriteColor(color: Color, file: File) -> void:
	file.store_8(color.b * 255)
	file.store_8(color.g * 255)
	file.store_8(color.r * 255)
	file.store_8(color.a * 255)

static func ReadBasis(file: File) -> Basis:
	var b = Basis(
		ReadVector3(file, 1),
		ReadVector3(file, 1),
		ReadVector3(file, 1)
	)
	return b

static func WriteBasis(basis: Basis, file: File) -> void:
	WriteVector3(basis.x.normalized(), file, 1)
	WriteVector3(basis.y.normalized(), file, 1)
	WriteVector3(basis.z.normalized(), file, 1)