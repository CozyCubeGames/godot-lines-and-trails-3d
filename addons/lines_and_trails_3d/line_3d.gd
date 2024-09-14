@tool

class_name Line3D
extends MeshInstance3D


enum TextureTileMode { RATIO, DISTANCE }


const DEFAULT_MATERIAL: Material = preload("res://addons/lines_and_trails_3d/default_line_3d_mix.material")

@export_range(0.0, 1.0) var width: float = 0.05:
	set(value):
		width = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var width_curve: Curve = _get_default_width_curve():
	set(value):
		width_curve = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var gradient: Gradient = _get_default_gradient():
	set(value):
		gradient = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export_range(0.0, 1.0) var alpha: float = 1.0:
	set(value):
		alpha = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var use_global_space: bool = false:
	set(value):
		use_global_space = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var texture_tile_mode: TextureTileMode = TextureTileMode.RATIO:
	set(value):
		texture_tile_mode = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var points: PackedVector3Array:
	set(value):
		points = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()

var _vertices: PackedVector3Array
var _tangents: PackedVector3Array
var _colors: PackedColorArray
var _uvs: PackedVector2Array
var _indices: PackedInt32Array
var _arrays: Array
var _auto_rebuild: bool = true


func _init() -> void:

	_arrays.resize(Mesh.ARRAY_MAX)
	_arrays[Mesh.ARRAY_VERTEX] = _vertices
	_arrays[Mesh.ARRAY_NORMAL] = _tangents
	_arrays[Mesh.ARRAY_COLOR] = _colors
	_arrays[Mesh.ARRAY_TEX_UV] = _uvs
	_arrays[Mesh.ARRAY_INDEX] = _indices


func _validate_property(property: Dictionary) -> void:

	if property.name == "mesh":
		property.usage = PROPERTY_USAGE_NONE


func _ready() -> void:

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
	_tangents.resize(point_count * 3)
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

	var half_width := width / 2
	var inv_global_tf: Transform3D

	if use_global_space:
		inv_global_tf = global_transform.inverse()

	var length: float = 0.0

	for i in point_count:

		var j0 := i * 3
		var j1 := j0 + 1
		var j2 := j0 + 2

		var p := points[i]

		if i > 0:
			length += points[i - 1].distance_to(p)

		var tangent: Vector3
		if i == 0:
			tangent = (points[i + 1] - p).normalized()
		elif i == point_count - 1:
			tangent = (p - points[i - 1]).normalized()
		else:
			tangent = (p - points[i - 1]).lerp(points[i + 1] - p, 0.5).normalized()

		if use_global_space:
			p = inv_global_tf * p
			tangent = inv_global_tf.basis * tangent

		_vertices[j0] = p
		_vertices[j1] = p
		_vertices[j2] = p
		_tangents[j0] = tangent
		_tangents[j1] = tangent
		_tangents[j2] = tangent

		var u: float
		match texture_tile_mode:
			TextureTileMode.RATIO:
				u = float(i) / (point_count - 1)
			TextureTileMode.DISTANCE:
				u = length

		var c := gradient.sample(u) if gradient else Color.WHITE
		c.a *= alpha
		_colors[j0] = c
		_colors[j1] = c
		_colors[j2] = c

		var v := half_width
		if width_curve:
			v *= width_curve.sample(u)
		_uvs[j0] = Vector2(u, -v)
		_uvs[j1] = Vector2(u, 0)
		_uvs[j2] = Vector2(u, v)

	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	am.surface_set_material(0, DEFAULT_MATERIAL)


func _get_default_width_curve() -> Curve:

	var c := Curve.new()
	c.clear_points()
	c.add_point(Vector2(0, 1), 0, 0, Curve.TangentMode.TANGENT_LINEAR)
	c.add_point(Vector2(1, 1), 0, 0, Curve.TangentMode.TANGENT_LINEAR)
	return c


func _get_default_gradient() -> Gradient:

	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color.WHITE)
	return g
