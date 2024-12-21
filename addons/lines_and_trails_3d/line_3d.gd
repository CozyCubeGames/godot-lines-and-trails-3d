@tool

class_name Line3D
extends MeshInstance3D


enum TextureTileMode { RATIO, DISTANCE }
enum BillboardMode { NONE, VIEW, Z }


const DEFAULT_MATERIAL: Material = preload("res://addons/lines_and_trails_3d/default_line_3d_mix.material")

@export_range(0.0, 1.0) var width: float = 0.05:
	set(value):
		if width == value:
			return
		width = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var width_curve: Curve:
	set(value):
		if width_curve == value:
			return
		width_curve = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var gradient: Gradient:
	set(value):
		if gradient == value:
			return
		gradient = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export_range(0.0, 1.0) var alpha: float = 1.0:
	set(value):
		if alpha == value:
			return
		alpha = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var use_global_space: bool = false:
	set(value):
		use_global_space = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var billboard_mode: BillboardMode = BillboardMode.VIEW:
	set(value):
		if billboard_mode == value:
			return
		billboard_mode = value
		notify_property_list_changed()
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var texture_tile_mode: TextureTileMode = TextureTileMode.RATIO:
	set(value):
		if texture_tile_mode == value:
			return
		texture_tile_mode = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var texture_offset: float = 0.0:
	set(value):
		if texture_offset == value:
			return
		texture_offset = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var points: PackedVector3Array:
	set(value):
		points = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var curve_normals: PackedVector3Array:
	set(value):
		curve_normals = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()

var _vertices: PackedVector3Array
var _normals: PackedVector3Array
var _colors: PackedColorArray
var _uvs: PackedVector2Array
var _indices: PackedInt32Array
var _arrays: Array
var _auto_rebuild: bool = true


func _init() -> void:

	_arrays.resize(Mesh.ARRAY_MAX)
	_arrays[Mesh.ARRAY_VERTEX] = _vertices
	_arrays[Mesh.ARRAY_NORMAL] = _normals
	_arrays[Mesh.ARRAY_COLOR] = _colors
	_arrays[Mesh.ARRAY_TEX_UV] = _uvs
	_arrays[Mesh.ARRAY_INDEX] = _indices


func _validate_property(property: Dictionary) -> void:

	match property.name:
		"mesh":
			property.usage = PROPERTY_USAGE_NONE
		"curve_normals":
			if billboard_mode != BillboardMode.NONE:
				property.usage = PROPERTY_USAGE_NONE


func _ready() -> void:

	rebuild()


func clear() -> void:
	
	points.clear()
	curve_normals.clear()
	_vertices.clear()
	_normals.clear()
	_colors.clear()
	_uvs.clear()
	_indices.clear()
	
	rebuild()


func rebuild() -> void:

	if not is_inside_tree():
		return

	if not is_instance_valid(mesh):
		mesh = ArrayMesh.new()

	var am := mesh as ArrayMesh
	am.clear_surfaces()

	var point_count := points.size()
	if point_count < 2:
		return

	_vertices.resize(point_count * 3)
	_normals.resize(point_count * 3)
	_colors.resize(point_count * 3)
	_uvs.resize(point_count * 3)

	var new_index_count := (point_count - 1) * 12
	if _indices.size() != new_index_count:
		_indices.resize(new_index_count)
		for i in point_count - 1:
			var j := i * 12
			var k := i * 3
			_indices[j] = k
			_indices[j + 1] = k + 3
			_indices[j + 2] = k + 1
			_indices[j + 3] = k + 1
			_indices[j + 4] = k + 3
			_indices[j + 5] = k + 4
			_indices[j + 6] = k + 1
			_indices[j + 7] = k + 4
			_indices[j + 8] = k + 2
			_indices[j + 9] = k + 2
			_indices[j + 10] = k + 4
			_indices[j + 11] = k + 5

	var inv_global_tf: Transform3D
	var z_dir: Vector3
	if use_global_space:
		inv_global_tf = global_transform.inverse()
		z_dir = inv_global_tf.basis.z
	else:
		z_dir = Vector3.BACK

	var length: float = 0.0
	for i in range(1, point_count):
		length += points[i - 1].distance_to(points[i])

	var dist: float = 0.0

	for i in point_count:

		var j0 := i * 3
		var j1 := j0 + 1
		var j2 := j0 + 2

		var p := points[i]

		if i > 0:
			dist += points[i - 1].distance_to(p)

		var ratio := (dist / length) if (length > 0) else 0

		var u: float
		match texture_tile_mode:
			TextureTileMode.RATIO:
				u = ratio
			TextureTileMode.DISTANCE:
				u = dist
		u += texture_offset

		var half_width := width / 2
		if width_curve:
			half_width *= width_curve.sample(ratio)

		var tangent: Vector3
		if i == 0:
			tangent = (points[i + 1] - p).normalized()
		elif i == point_count - 1:
			tangent = (p - points[i - 1]).normalized()
		else:
			tangent = (p - points[i - 1]).lerp(points[i + 1] - p, 0.5).normalized()

		if use_global_space:
			p = inv_global_tf * p

		if billboard_mode == BillboardMode.VIEW:

			_vertices[j0] = p
			_vertices[j1] = p
			_vertices[j2] = p
			if use_global_space:
				tangent = inv_global_tf.basis * tangent
			_normals[j0] = tangent
			_normals[j1] = tangent
			_normals[j2] = tangent
			_uvs[j0] = Vector2(u, -half_width)
			_uvs[j1] = Vector2(u, 0)
			_uvs[j2] = Vector2(u, half_width)

		else:

			var curve_normal: Vector3
			var normal: Vector3

			if billboard_mode == BillboardMode.Z:
				curve_normal = z_dir.cross(tangent).normalized()
				normal = z_dir
			else:
				curve_normal = curve_normals[i] if i < curve_normals.size() else z_dir.cross(tangent).normalized()
				normal = Vector3.BACK
				if use_global_space:
					normal = inv_global_tf.basis * normal

			if use_global_space:
				curve_normal = inv_global_tf.basis * curve_normal

			_vertices[j0] = p + half_width * curve_normal
			_vertices[j1] = p
			_vertices[j2] = p - half_width * curve_normal

			_normals[j0] = normal
			_normals[j1] = normal
			_normals[j2] = normal

			_uvs[j0] = Vector2(u, 0)
			_uvs[j1] = Vector2(u, 0.5)
			_uvs[j2] = Vector2(u, 1)

		var c := gradient.sample(ratio) if gradient else Color.WHITE
		c.a *= alpha
		_colors[j0] = c
		_colors[j1] = c
		_colors[j2] = c

	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	am.surface_set_material(0, DEFAULT_MATERIAL)
