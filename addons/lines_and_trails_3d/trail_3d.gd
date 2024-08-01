@tool

class_name Trail3D
extends Line3D


enum LimitMode {
	TIME,
	LENGTH
}


@export_range(0.01, 1.0) var max_section_length: float = 0.1:
	set(value):
		max_section_length = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var limit_mode: LimitMode = LimitMode.TIME:
	set(value):
		limit_mode = value
		notify_property_list_changed()
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var time_limit: float = 0.25:
	set(value):
		time_limit = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()
@export var length_limit: float = 1.0:
	set(value):
		length_limit = value
		if _auto_rebuild and Engine.is_editor_hint():
			rebuild()

var _prev_pos: Vector3
var _times: PackedFloat64Array


func _ready() -> void:

	_auto_rebuild = false
	_prev_pos = global_position
	process_priority = 9999
	use_global_space = true
	points.clear()
	_times.clear()

	rebuild()


func _validate_property(property: Dictionary) -> void:

	if property.name == "time_limit":
		if limit_mode != LimitMode.TIME:
			property.usage &= ~PROPERTY_USAGE_EDITOR
	elif property.name == "length_limit":
		if limit_mode != LimitMode.LENGTH:
			property.usage &= ~PROPERTY_USAGE_EDITOR
	elif property.name == "points":
		property.usage = PROPERTY_USAGE_NONE
	elif property.name == "use_global_space":
		property.usage = PROPERTY_USAGE_NONE
	else:
		super._validate_property(property)


func _process(delta: float) -> void:

	_step()


func _step() -> void:

	var pos := global_position
	var time := Time.get_ticks_msec() / 1000.0

	while points.size() < 2:
		points.insert(0, pos)
	while _times.size() < 2:
		_times.insert(0, time)

	points[0] = pos
	_times[0] = time
	_prev_pos = pos

	if points.size() >= 2:

		var leading := points[1]
		var from_leading := pos - leading
		var dist_from_leading := from_leading.length()

		if dist_from_leading > max_section_length:
			var dir_from_leading := from_leading / dist_from_leading
			var d: float = max_section_length
			while d < dist_from_leading:
				points.insert(1, leading + dir_from_leading * d)
				_times.insert(1, time)
				d += max_section_length

	if limit_mode == LimitMode.LENGTH:

		var last_index := points.size() - 1
		var total_length := 0.0
		for i in last_index:
			total_length += points[i].distance_to(points[i + 1])

		var extra_length := total_length - length_limit

		while extra_length > 0:
			var last_point := points[last_index]
			var second_last_point := points[last_index - 1]
			var last_section_length := last_point.distance_to(second_last_point)
			if last_section_length > extra_length:
				var shortened_section_length := last_section_length - extra_length
				points[last_index] = second_last_point + (last_point - second_last_point) * (shortened_section_length / last_section_length)
			else:
				points.remove_at(last_index)
				_times.remove_at(last_index)
				last_index -= 1
			extra_length -= last_section_length

	elif limit_mode == LimitMode.TIME:

		var last_index := _times.size() - 1
		var total_time := _times[0] - _times[last_index]
		var extra_time := total_time - time_limit

		while extra_time > 0:
			var last_time := _times[last_index]
			var second_last_time := _times[last_index - 1]
			var last_section_duration := second_last_time - last_time
			if last_section_duration > extra_time:
				var last_point := points[last_index]
				var second_last_point := points[last_index - 1]
				var shortened_section_duration := last_section_duration - extra_time
				var shortened_ratio := shortened_section_duration / last_section_duration
				points[last_index] = second_last_point + (last_point - second_last_point) * shortened_ratio
				_times[last_index] = second_last_time + (last_time - second_last_time) * shortened_ratio
			else:
				points.remove_at(last_index)
				_times.remove_at(last_index)
				last_index -= 1
			extra_time -= last_section_duration

	rebuild()


func _get_default_width_curve() -> Curve:

	var c := Curve.new()
	c.clear_points()
	c.add_point(Vector2(0, 1), -1, -1, Curve.TangentMode.TANGENT_LINEAR)
	c.add_point(Vector2(1, 0), -1, -1, Curve.TangentMode.TANGENT_LINEAR)
	return c
