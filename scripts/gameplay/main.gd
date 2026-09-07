extends Node

var game_manager: GameManager
var spawner: FruitSpawner
var slice_input: SliceInput
var audio_manager: AudioManager
var camera: Camera3D
var hud_label: Label
var combo_label: Label
var title_panel: Control
var title_label: Label
var subtitle_label: Label
var action_button: Button

func _ready() -> void:
	_build_world()
	_build_ui()
	_connect_gameplay()
	_show_start_screen()


func _build_world() -> void:
	var world := Node3D.new()
	world.name = "World"
	add_child(world)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 0.0, 12.0)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.2
	camera.current = true
	world.add_child(camera)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-25.0, -25.0, 0.0)
	key_light.light_color = Color("fff1d2")
	key_light.light_energy = 1.5
	key_light.shadow_enabled = false
	world.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(20.0, 145.0, 0.0)
	fill_light.light_color = Color("80aaff")
	fill_light.light_energy = 0.75
	world.add_child(fill_light)

	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("071027")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("879ddb")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	world.add_child(environment)

	spawner = FruitSpawner.new()
	spawner.name = "FruitSpawner"
	world.add_child(spawner)

	game_manager = GameManager.new()
	game_manager.name = "GameManager"
	add_child(game_manager)

	audio_manager = AudioManager.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)

	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.04, 0.1, 0.22)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(backdrop)

	hud_label = Label.new()
	hud_label.position = Vector2(28.0, 22.0)
	hud_label.add_theme_font_size_override("font_size", 26)
	hud_label.add_theme_color_override("font_color", Color("f9f3df"))
	canvas.add_child(hud_label)

	combo_label = Label.new()
	combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	combo_label.position = Vector2(-130.0, 24.0)
	combo_label.size = Vector2(260.0, 60.0)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_size_override("font_size", 34)
	combo_label.add_theme_color_override("font_color", Color("ffe070"))
	canvas.add_child(combo_label)

	var trail := Line2D.new()
	trail.width = 10.0
	trail.default_color = Color("e8fbff")
	trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	trail.joint_mode = Line2D.LINE_JOINT_ROUND
	trail.antialiased = true
	canvas.add_child(trail)

	slice_input = SliceInput.new()
	slice_input.name = "SliceInput"
	add_child(slice_input)
	slice_input.setup(camera, trail)

	title_panel = CenterContainer.new()
	title_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(title_panel)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 330.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.15, 0.94)
	style.border_color = Color("5de0e6")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.content_margin_left = 42.0
	style.content_margin_right = 42.0
	style.content_margin_top = 38.0
	style.content_margin_bottom = 38.0
	panel.add_theme_stylebox_override("panel", style)
	title_panel.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	panel.add_child(stack)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 54)
	title_label.add_theme_color_override("font_color", Color("ffce57"))
	stack.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 21)
	subtitle_label.add_theme_color_override("font_color", Color("c9d9ff"))
	stack.add_child(subtitle_label)
	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(280.0, 64.0)
	action_button.add_theme_font_size_override("font_size", 24)
	stack.add_child(action_button)


func _connect_gameplay() -> void:
	action_button.pressed.connect(_start_game)
	game_manager.hud_changed.connect(_update_hud)
	game_manager.state_changed.connect(_on_state_changed)
	spawner.item_spawned.connect(_on_item_spawned)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_game") and game_manager.state != GameManager.State.PLAYING:
		_start_game()


func _process(_delta: float) -> void:
	if game_manager.state == GameManager.State.PLAYING:
		spawner.set_difficulty(game_manager.difficulty())


func _start_game() -> void:
	spawner.clear_items()
	slice_input.reset()
	game_manager.start_run()
	spawner.begin(camera)
	slice_input.enabled = true
	title_panel.visible = false


func _show_start_screen() -> void:
	title_label.text = "FRUIT SLASH"
	subtitle_label.text = "Slice fruit. Chain combos. Avoid bombs."
	action_button.text = "START RUN"
	title_panel.visible = true
	hud_label.text = ""
	combo_label.text = ""


func _on_item_spawned(item: Sliceable) -> void:
	item.sliced.connect(_on_fruit_sliced)
	item.escaped.connect(_on_item_escaped)
	item.bomb_hit.connect(_on_bomb_hit)


func _on_fruit_sliced(_item: Sliceable, _position: Vector2, points: int) -> void:
	game_manager.record_slice(points)
	audio_manager.play_slice()


func _on_item_escaped(item: Sliceable) -> void:
	if item.kind == Sliceable.Kind.FRUIT:
		game_manager.record_miss()


func _on_bomb_hit(_item: Sliceable) -> void:
	audio_manager.play_danger()
	game_manager.end_run()


func _update_hud(score: int, lives: int, combo: int, high_score: int) -> void:
	hud_label.text = "SCORE  %05d\nBEST   %05d\nLIVES  %s" % [score, high_score, "●".repeat(maxi(lives, 0))]
	combo_label.text = "COMBO ×%d" % combo if combo >= 2 else ""


func _on_state_changed(state: GameManager.State) -> void:
	if state != GameManager.State.GAME_OVER:
		return
	spawner.stop()
	slice_input.enabled = false
	await get_tree().create_timer(0.35).timeout
	title_label.text = "RUN OVER"
	subtitle_label.text = "Score  %d\nBest  %d" % [game_manager.score, game_manager.high_score]
	action_button.text = "SLASH AGAIN"
	title_panel.visible = true

