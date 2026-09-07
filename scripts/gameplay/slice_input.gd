class_name SliceInput
extends Node

signal swipe_started

const MAX_TRAIL_POINTS := 18
const SAMPLE_SPACING := 18.0

var camera: Camera3D
var enabled := false
var dragging := false
var last_position := Vector2.ZERO
var trail: Line2D
var trail_points: Array[Vector2] = []
var fade_clock := 0.0

func setup(view_camera: Camera3D, line: Line2D) -> void:
	camera = view_camera
	trail = line


func reset() -> void:
	dragging = false
	trail_points.clear()
	_update_trail()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe()
	elif event is InputEventMouseMotion and dragging:
		_sample_segment(last_position, event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_swipe(event.position)
		else:
			_end_swipe()
	elif event is InputEventScreenDrag:
		if dragging:
			_sample_segment(last_position, event.position)


func _process(delta: float) -> void:
	if not dragging and not trail_points.is_empty():
		fade_clock -= delta
		if fade_clock <= 0.0:
			trail_points.pop_front()
			fade_clock = 0.018
			_update_trail()


func _begin_swipe(position_2d: Vector2) -> void:
	dragging = true
	last_position = position_2d
	trail_points.clear()
	trail_points.append(position_2d)
	_update_trail()
	swipe_started.emit()


func _end_swipe() -> void:
	dragging = false
	fade_clock = 0.015


func _sample_segment(from: Vector2, to: Vector2) -> void:
	var distance := from.distance_to(to)
	if distance < 2.0:
		return
	var direction := (to - from).normalized()
	var samples := maxi(1, ceili(distance / SAMPLE_SPACING))
	for index in samples + 1:
		var point := from.lerp(to, float(index) / float(samples))
		_query_at(point, direction)
	trail_points.append(to)
	while trail_points.size() > MAX_TRAIL_POINTS:
		trail_points.pop_front()
	last_position = to
	_update_trail()


func _query_at(screen_position: Vector2, direction: Vector2) -> void:
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	var plane := Plane(Vector3.FORWARD, 0.0)
	var hit_position: Variant = plane.intersects_ray(ray_origin, ray_direction)
	if hit_position == null:
		return
	var sphere := SphereShape3D.new()
	sphere.radius = 0.34
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, hit_position as Vector3)
	query.collision_mask = 1
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hits := camera.get_world_3d().direct_space_state.intersect_shape(query, 8)
	for hit in hits:
		var collider: Variant = hit.get("collider")
		if collider is Sliceable:
			(collider as Sliceable).slice_at(screen_position, direction)


func _update_trail() -> void:
	if trail == null:
		return
	trail.clear_points()
	for point in trail_points:
		trail.add_point(point)

