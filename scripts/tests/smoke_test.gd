extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)


func _run() -> void:
	var manager := GameManager.new()
	root.add_child(manager)
	manager.start_run()
	_check(manager.state == GameManager.State.PLAYING, "run enters playing state")
	_check(manager.score == 0 and manager.lives == 3, "run resets score and lives")
	manager.start_run(GameManager.Difficulty.BREEZY)
	var breezy_pressure := manager.difficulty()
	manager.start_run(GameManager.Difficulty.FRENZY)
	var frenzy_pressure := manager.difficulty()
	_check(breezy_pressure < frenzy_pressure, "difficulty presets increase starting spawn pressure")
	manager.start_run(GameManager.Difficulty.CLASSIC)
	var opening_pressure := manager.difficulty()
	manager.elapsed = 75.0
	_check(manager.difficulty() > opening_pressure, "spawn pressure ramps during a run")
	manager.elapsed = 0.0
	manager.record_slice(10)
	manager.record_slice(10)
	manager.record_slice(10)
	manager.record_slice(10)
	_check(manager.score == 50, "combo multiplier applies after three chained slices")
	manager.record_miss()
	manager.record_miss()
	manager.record_miss()
	_check(manager.state == GameManager.State.GAME_OVER, "three misses end the run")

	var fruit := Sliceable.new()
	root.add_child(fruit)
	fruit.configure(Sliceable.Kind.FRUIT, 0, Vector3.ZERO, null)
	var slice_count := [0]
	fruit.sliced.connect(func(_item: Sliceable, _position: Vector2, _points: int) -> void: slice_count[0] += 1)
	fruit.slice_at(Vector2.ZERO, Vector2.RIGHT)
	fruit.slice_at(Vector2.ZERO, Vector2.RIGHT)
	_check(slice_count[0] == 1, "a fruit cannot score twice")

	var scene := load("res://scenes/game/main.tscn") as PackedScene
	_check(scene != null, "main scene loads")
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.get_node_or_null("World/FruitSpawner") != null, "gameplay world is wired")
	_check(game.get_node_or_null("UI") != null, "HUD is wired")

	print("Smoke test complete: %d failure(s)" % failures)
	quit(failures)
