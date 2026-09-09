class_name Sliceable
extends Area3D

signal sliced(item: Sliceable, screen_position: Vector2, points: int)
signal escaped(item: Sliceable)
signal bomb_hit(item: Sliceable)

enum Kind { FRUIT, BOMB }

const FRUIT_MODELS: Array[PackedScene] = [
	preload("res://assets/models/apple.glb"),
	preload("res://assets/models/orange.glb"),
	preload("res://assets/models/pear.glb"),
	preload("res://assets/models/plum.glb"),
]
const HALF_MODELS: Array[PackedScene] = [
	preload("res://assets/models/apple_half.glb"),
	preload("res://assets/models/orange_half.glb"),
	preload("res://assets/models/pear_half.glb"),
	preload("res://assets/models/plum_half.glb"),
]
const FRUIT_COLORS: Array[Color] = [
	Color("d10916"), Color("ff5f08"), Color("84c714"), Color("52108c")
]
const BOMB_MODEL: PackedScene = preload("res://assets/models/bomb.glb")

var kind: Kind = Kind.FRUIT
var fruit_style := 0
var velocity := Vector3.ZERO
var gravity_strength := 10.5
var point_value := 10
var was_sliced := false
var has_entered_playfield := false
var fruit_color := Color.WHITE
var camera: Camera3D
var visual: Node3D
var elapsed := 0.0

func configure(item_kind: Kind, style: int, launch_velocity: Vector3, view_camera: Camera3D) -> void:
	kind = item_kind
	fruit_style = clampi(style, 0, FRUIT_MODELS.size() - 1)
	fruit_color = FRUIT_COLORS[fruit_style]
	velocity = launch_velocity
	camera = view_camera
	collision_layer = 1
	collision_mask = 0
	monitoring = false
	monitorable = true
	_build_visual()


func _build_visual() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)

	var model_scene := BOMB_MODEL if kind == Kind.BOMB else FRUIT_MODELS[fruit_style]
	var model := model_scene.instantiate() as Node3D
	model.name = "BlenderModel"
	visual.add_child(model)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	collision.shape = sphere
	add_child(collision)

func _physics_process(delta: float) -> void:
	if was_sliced:
		return
	elapsed += delta
	velocity.y -= gravity_strength * delta
	position += velocity * delta
	visual.rotate(Vector3(0.35, 0.8, 0.2).normalized(), delta * 2.6)
	if position.y > -3.1:
		has_entered_playfield = true
	if has_entered_playfield and position.y < -5.2 and velocity.y < 0.0:
		escaped.emit(self)
		queue_free()
	elif elapsed > 12.0:
		queue_free()


func slice_at(screen_position: Vector2, direction: Vector2) -> void:
	if was_sliced:
		return
	was_sliced = true
	collision_layer = 0
	if kind == Kind.BOMB:
		bomb_hit.emit(self)
		queue_free()
		return
	sliced.emit(self, screen_position, point_value)
	_spawn_halves(direction)
	_spawn_juice()
	visual.visible = false
	await get_tree().create_timer(0.9).timeout
	queue_free()


func _spawn_halves(direction: Vector2) -> void:
	for side in [-1.0, 1.0]:
		var half := HALF_MODELS[fruit_style].instantiate() as Node3D
		half.name = "BlenderHalf"
		half.scale.x = side
		half.position.x = side * 0.12
		add_child(half)
		var tween := create_tween().set_parallel(true)
		var drift := Vector3(side * (0.85 + absf(direction.x) * 0.01), 0.45, side * 0.25)
		tween.tween_property(half, "position", half.position + drift, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(half, "rotation:z", side * 2.8, 0.75)
		tween.tween_property(half, "scale", half.scale * 0.55, 0.75).set_delay(0.25)


func _spawn_juice() -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 18
	particles.one_shot = true
	particles.lifetime = 0.6
	particles.explosiveness = 0.95
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 180.0
	process.initial_velocity_min = 2.0
	process.initial_velocity_max = 4.5
	process.gravity = Vector3(0.0, -5.0, 0.0)
	process.scale_min = 0.04
	process.scale_max = 0.12
	process.color = fruit_color.lightened(0.15)
	particles.process_material = process
	var drop := SphereMesh.new()
	drop.radius = 0.06
	drop.height = 0.12
	drop.radial_segments = 6
	drop.rings = 3
	particles.draw_pass_1 = drop
	add_child(particles)
	particles.emitting = true
