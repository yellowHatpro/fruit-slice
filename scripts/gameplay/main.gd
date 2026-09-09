extends Node

var game_manager: GameManager
var spawner: FruitSpawner
var slice_input: SliceInput
var audio_manager: AudioManager
var camera: Camera3D
var hud_label: Label
var combo_label: Label
var title_panel: Control
var menu_card: PanelContainer
var title_label: Label
var subtitle_label: Label
var difficulty_picker: OptionButton
var difficulty_hint: Label
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
	_build_background_plane(world)

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


func _build_background_plane(world: Node3D) -> void:
	var backdrop := MeshInstance3D.new()
	backdrop.name = "ArcadeBackdrop"
	var quad := QuadMesh.new()
	quad.size = Vector2(20.0, 12.0)
	backdrop.mesh = quad
	backdrop.position = Vector3(0.0, 0.0, -2.0)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled;

float line_segment(vec2 p, vec2 a, vec2 b, float width) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return 1.0 - smoothstep(width, width * 1.8, length(pa - ba * h));
}

void fragment() {
	vec2 uv = UV;
	float pulse = sin(TIME * 0.7) * 0.5 + 0.5;
	float cyan_glow = exp(-8.0 * distance(uv, vec2(0.13 + pulse * 0.03, 0.2)));
	float pink_glow = exp(-7.0 * distance(uv, vec2(0.88 - pulse * 0.025, 0.78)));
	float horizon = exp(-18.0 * abs(uv.y - 0.72));
	vec3 color = mix(vec3(0.012, 0.025, 0.075), vec3(0.025, 0.045, 0.13), uv.y);
	color += vec3(0.02, 0.32, 0.42) * cyan_glow * 0.42;
	color += vec3(0.48, 0.025, 0.24) * pink_glow * 0.32;
	color += vec3(0.04, 0.22, 0.28) * horizon * 0.2;
	float cyan_streaks = line_segment(uv, vec2(0.05,0.18), vec2(0.26,0.52),0.0025);
	cyan_streaks += line_segment(uv, vec2(0.78,0.15), vec2(0.92,0.34),0.0018);
	float pink_streak = line_segment(uv, vec2(0.75,0.82), vec2(0.94,0.48),0.0018);
	float cyan_orb = 1.0 - smoothstep(0.035, 0.038, distance(uv,vec2(0.1,0.82)));
	float pink_orb = 1.0 - smoothstep(0.06, 0.064, distance(uv,vec2(0.87,0.2)));
	float gold_orb = 1.0 - smoothstep(0.023, 0.026, distance(uv,vec2(0.88,0.86)));
	color += vec3(0.12,0.7,0.85) * (cyan_streaks*0.3 + cyan_orb*0.13);
	color += vec3(0.9,0.08,0.4) * (pink_streak*0.23 + pink_orb*0.13);
	color += vec3(0.95,0.58,0.12) * gold_orb*0.12;
	float vignette = smoothstep(0.85, 0.25, distance(uv, vec2(0.5)));
	ALBEDO = color * (0.72 + vignette * 0.38);
	EMISSION = ALBEDO;
	ROUGHNESS = 1.0;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	backdrop.material_override = material
	world.add_child(backdrop)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	canvas.layer = 1
	add_child(canvas)

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
	menu_card = PanelContainer.new()
	menu_card.custom_minimum_size = Vector2(580.0, 500.0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.022, 0.04, 0.105, 0.97)
	style.border_color = Color("53e4ee")
	style.set_border_width_all(3)
	style.set_corner_radius_all(28)
	style.content_margin_left = 48.0
	style.content_margin_right = 48.0
	style.content_margin_top = 34.0
	style.content_margin_bottom = 34.0
	style.shadow_color = Color(0.0, 0.75, 0.9, 0.18)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0.0, 8.0)
	menu_card.add_theme_stylebox_override("panel", style)
	title_panel.add_child(menu_card)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 13)
	menu_card.add_child(stack)
	var badge := Label.new()
	badge.text = "◆  3D ARCADE  ·  SLICE & SURVIVE  ◆"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 14)
	badge.add_theme_color_override("font_color", Color("62e8ef"))
	badge.add_theme_constant_override("outline_size", 4)
	badge.add_theme_color_override("font_outline_color", Color(0.02, 0.3, 0.4, 0.35))
	stack.add_child(badge)
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 62)
	title_label.add_theme_color_override("font_color", Color("ffd34e"))
	title_label.add_theme_constant_override("outline_size", 7)
	title_label.add_theme_color_override("font_outline_color", Color("8c2e5e"))
	title_label.add_theme_constant_override("shadow_offset_x", 4)
	title_label.add_theme_constant_override("shadow_offset_y", 5)
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	stack.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 21)
	subtitle_label.add_theme_color_override("font_color", Color("c9d9ff"))
	stack.add_child(subtitle_label)
	var separator := HSeparator.new()
	separator.custom_minimum_size.y = 8.0
	separator.add_theme_stylebox_override("separator", _flat_style(Color(0.23, 0.72, 0.82, 0.38), 1))
	stack.add_child(separator)
	var difficulty_label := Label.new()
	difficulty_label.text = "CHOOSE YOUR PRESSURE"
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.add_theme_font_size_override("font_size", 16)
	difficulty_label.add_theme_color_override("font_color", Color("79dce4"))
	stack.add_child(difficulty_label)
	difficulty_picker = OptionButton.new()
	difficulty_picker.custom_minimum_size = Vector2(330.0, 52.0)
	difficulty_picker.add_theme_font_size_override("font_size", 20)
	difficulty_picker.add_theme_color_override("font_color", Color("f5f7ff"))
	difficulty_picker.add_theme_color_override("font_hover_color", Color.WHITE)
	difficulty_picker.add_theme_stylebox_override("normal", _flat_style(Color("121a38"), 12, Color("344778"), 2))
	difficulty_picker.add_theme_stylebox_override("hover", _flat_style(Color("18264c"), 12, Color("52dfe8"), 2))
	difficulty_picker.add_theme_stylebox_override("pressed", _flat_style(Color("1d2f5b"), 12, Color("ffd34e"), 2))
	difficulty_picker.add_theme_stylebox_override("focus", _flat_style(Color("152345"), 12, Color("52dfe8"), 2))
	difficulty_picker.add_item("Breezy", GameManager.Difficulty.BREEZY)
	difficulty_picker.add_item("Classic", GameManager.Difficulty.CLASSIC)
	difficulty_picker.add_item("Frenzy", GameManager.Difficulty.FRENZY)
	difficulty_picker.select(GameManager.Difficulty.CLASSIC)
	stack.add_child(difficulty_picker)
	var hint_panel := PanelContainer.new()
	hint_panel.custom_minimum_size = Vector2(410.0, 38.0)
	hint_panel.add_theme_stylebox_override("panel", _flat_style(Color(0.08, 0.12, 0.25, 0.72), 12))
	stack.add_child(hint_panel)
	difficulty_hint = Label.new()
	difficulty_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	difficulty_hint.add_theme_font_size_override("font_size", 15)
	difficulty_hint.add_theme_color_override("font_color", Color("a8b9df"))
	hint_panel.add_child(difficulty_hint)
	_update_difficulty_hint(GameManager.Difficulty.CLASSIC)
	action_button = Button.new()
	action_button.custom_minimum_size = Vector2(280.0, 64.0)
	action_button.add_theme_font_size_override("font_size", 25)
	action_button.add_theme_color_override("font_color", Color("11152b"))
	action_button.add_theme_color_override("font_hover_color", Color("11152b"))
	action_button.add_theme_color_override("font_pressed_color", Color("11152b"))
	action_button.add_theme_stylebox_override("normal", _flat_style(Color("ffd34e"), 15, Color("fff1a0"), 2, Color(0.95, 0.25, 0.35, 0.32), 9))
	action_button.add_theme_stylebox_override("hover", _flat_style(Color("ffec79"), 15, Color.WHITE, 3, Color(0.3, 0.9, 1.0, 0.36), 13))
	action_button.add_theme_stylebox_override("pressed", _flat_style(Color("f5b936"), 15, Color("ffdf65"), 2))
	action_button.add_theme_stylebox_override("focus", _flat_style(Color("ffdb55"), 15, Color("55e5ee"), 3))
	stack.add_child(action_button)
	var controls_hint := Label.new()
	controls_hint.text = "DRAG / SWIPE TO SLICE   ·   SPACE TO START"
	controls_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_hint.add_theme_font_size_override("font_size", 13)
	controls_hint.add_theme_color_override("font_color", Color("7185b8"))
	stack.add_child(controls_hint)


func _flat_style(color: Color, radius: int, border_color := Color.TRANSPARENT, border_width := 0, shadow_color := Color.TRANSPARENT, shadow_size := 0) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.border_color = border_color
	result.set_border_width_all(border_width)
	result.set_corner_radius_all(radius)
	result.shadow_color = shadow_color
	result.shadow_size = shadow_size
	return result


func _connect_gameplay() -> void:
	action_button.pressed.connect(_start_game)
	difficulty_picker.item_selected.connect(_on_difficulty_selected)
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
	var difficulty_level := difficulty_picker.get_item_id(difficulty_picker.selected)
	game_manager.start_run(difficulty_level)
	spawner.begin(camera, game_manager.difficulty())
	slice_input.enabled = true
	title_panel.visible = false


func _show_start_screen() -> void:
	title_label.text = "FRUIT SLASH"
	subtitle_label.text = "Slice fruit. Chain combos. Avoid bombs."
	action_button.text = "START RUN"
	_reveal_menu()
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
	hud_label.text = "SCORE  %05d\nBEST   %05d\nLIVES  %s\nMODE   %s" % [score, high_score, "●".repeat(maxi(lives, 0)), game_manager.difficulty_name()]
	combo_label.text = "COMBO ×%d" % combo if combo >= 2 else ""


func _on_difficulty_selected(index: int) -> void:
	_update_difficulty_hint(difficulty_picker.get_item_id(index))


func _update_difficulty_hint(level: int) -> void:
	match level:
		GameManager.Difficulty.BREEZY:
			difficulty_hint.text = "Gentler pacing · fewer batches · fewer bombs"
		GameManager.Difficulty.FRENZY:
			difficulty_hint.text = "Rapid launches · larger batches · more bombs"
		_:
			difficulty_hint.text = "Balanced pacing with a steady difficulty ramp"


func _reveal_menu() -> void:
	title_panel.visible = true
	title_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(title_panel, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_state_changed(state: GameManager.State) -> void:
	if state != GameManager.State.GAME_OVER:
		return
	spawner.stop()
	slice_input.enabled = false
	await get_tree().create_timer(0.35).timeout
	title_label.text = "RUN OVER"
	subtitle_label.text = "%s RUN  ·  Score %d\nBest  %d" % [game_manager.difficulty_name(), game_manager.score, game_manager.high_score]
	action_button.text = "SLASH AGAIN"
	_reveal_menu()
