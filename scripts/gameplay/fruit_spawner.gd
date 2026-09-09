class_name FruitSpawner
extends Node3D

signal item_spawned(item: Sliceable)

var camera: Camera3D
var active := false
var difficulty := 1.0
var spawn_clock := 0.0
var random := RandomNumberGenerator.new()
func _ready() -> void:
	random.randomize()


func begin(view_camera: Camera3D) -> void:
	camera = view_camera
	active = true
	difficulty = 1.0
	spawn_clock = 0.35


func stop() -> void:
	active = false


func set_difficulty(value: float) -> void:
	difficulty = clampf(value, 1.0, 2.2)


func clear_items() -> void:
	for child in get_children():
		child.queue_free()


func _process(delta: float) -> void:
	if not active:
		return
	spawn_clock -= delta
	if spawn_clock <= 0.0:
		_spawn_batch()
		spawn_clock = random.randf_range(0.7, 1.15) / difficulty


func _spawn_batch() -> void:
	var count := 1
	if random.randf() < 0.2 + (difficulty - 1.0) * 0.35:
		count = 2
	if difficulty > 1.55 and random.randf() < 0.22:
		count = 3
	for index in count:
		var bomb_chance := minf(0.08 + (difficulty - 1.0) * 0.07, 0.16)
		_spawn_item(Sliceable.Kind.BOMB if random.randf() < bomb_chance else Sliceable.Kind.FRUIT, index, count)


func _spawn_item(kind: Sliceable.Kind, index: int, count: int) -> void:
	var item := Sliceable.new()
	item.name = "Bomb" if kind == Sliceable.Kind.BOMB else "Fruit"
	var lane_offset := (float(index) - (float(count) - 1.0) * 0.5) * 1.35
	var start_x := random.randf_range(-4.7, 4.7) + lane_offset
	start_x = clampf(start_x, -5.3, 5.3)
	item.position = Vector3(start_x, -4.6, random.randf_range(-0.35, 0.35))
	var horizontal := random.randf_range(-1.8, 1.8) - start_x * 0.12
	var upward := random.randf_range(8.5, 10.4) + difficulty * 0.3
	var fruit_style := random.randi_range(0, Sliceable.FRUIT_MODELS.size() - 1)
	add_child(item)
	item.configure(kind, fruit_style, Vector3(horizontal, upward, 0.0), camera)
	item_spawned.emit(item)
