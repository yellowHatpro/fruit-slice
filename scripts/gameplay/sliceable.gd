class_name Sliceable
extends Area3D

signal sliced(item: Sliceable, screen_position: Vector2, points: int)
signal escaped(item: Sliceable)
signal bomb_hit(item: Sliceable)

enum Kind { FRUIT, BOMB }

var kind: Kind = Kind.FRUIT
var velocity := Vector3.ZERO
var gravity_strength := 10.5
var point_value := 10
var was_sliced := false
var has_entered_playfield := false
var fruit_color := Color.WHITE
var camera: Camera3D
var visual: Node3D
var elapsed := 0.0

func configure(item_kind: Kind, color: Color, launch_velocity: Vector3, view_camera: Camera3D) -> void:
	kind = item_kind
	fruit_color = color
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

	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.48
	mesh.height = 0.96
	mesh.radial_segments = 16
	mesh.rings = 8
	body.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.08, 0.1) if kind == Kind.BOMB else fruit_color
	material.roughness = 0.42
	material.metallic = 0.65 if kind == Kind.BOMB else 0.05
	body.material_override = material
	visual.add_child(body)

	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	collision.shape = sphere
	add_child(collision)

	if kind == Kind.BOMB:
		_add_bomb_details()
	else:
		_add_fruit_details()


func _add_fruit_details() -> void:
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.045
	stem_mesh.bottom_radius = 0.065
	stem_mesh.height = 0.3
	stem.mesh = stem_mesh
	stem.position.y = 0.55
	stem.rotation.z = -0.22
	var stem_material := StandardMaterial3D.new()
	stem_material.albedo_color = Color("5b3a24")
	stem.material_override = stem_material
	visual.add_child(stem)

	var leaf := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 0.14
	leaf_mesh.height = 0.28
	leaf.mesh = leaf_mesh
	leaf.scale = Vector3(1.4, 0.25, 0.7)
	leaf.position = Vector3(0.14, 0.62, 0.0)
	leaf.rotation.z = -0.5
	var leaf_material := StandardMaterial3D.new()
	leaf_material.albedo_color = Color("65d96f")
	leaf.material_override = leaf_material
	visual.add_child(leaf)


func _add_bomb_details() -> void:
	var band := MeshInstance3D.new()
	var band_mesh := TorusMesh.new()
	band_mesh.inner_radius = 0.43
	band_mesh.outer_radius = 0.49
	band_mesh.rings = 12
	band_mesh.ring_segments = 16
	band.mesh = band_mesh
	band.rotation.x = PI * 0.5
	var band_material := StandardMaterial3D.new()
	band_material.albedo_color = Color("ff4f45")
	band_material.emission_enabled = true
	band_material.emission = Color("7c1616")
	band.material_override = band_material
	visual.add_child(band)

	var fuse := MeshInstance3D.new()
	var fuse_mesh := CylinderMesh.new()
	fuse_mesh.top_radius = 0.04
	fuse_mesh.bottom_radius = 0.04
	fuse_mesh.height = 0.38
	fuse.mesh = fuse_mesh
	fuse.position = Vector3(0.12, 0.59, 0.0)
	fuse.rotation.z = -0.55
	var fuse_material := StandardMaterial3D.new()
	fuse_material.albedo_color = Color("f7c95c")
	fuse_material.emission_enabled = true
	fuse_material.emission = Color("db6b26")
	fuse.material_override = fuse_material
	visual.add_child(fuse)


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
		var half := MeshInstance3D.new()
		var half_mesh := SphereMesh.new()
		half_mesh.radius = 0.47
		half_mesh.height = 0.9
		half_mesh.radial_segments = 12
		half_mesh.rings = 6
		half.mesh = half_mesh
		half.scale = Vector3(0.48, 1.0, 1.0)
		half.position.x = side * 0.24
		var material := StandardMaterial3D.new()
		material.albedo_color = fruit_color.lightened(0.08)
		material.roughness = 0.48
		half.material_override = material
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
