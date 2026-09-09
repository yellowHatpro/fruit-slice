class_name GameManager
extends Node

signal hud_changed(score: int, lives: int, combo: int, high_score: int)
signal state_changed(state: State)

enum State { START, PLAYING, GAME_OVER }
enum Difficulty { BREEZY, CLASSIC, FRENZY }

const DIFFICULTY_NAMES: Array[String] = ["BREEZY", "CLASSIC", "FRENZY"]
const BASE_PRESSURE: Array[float] = [0.82, 1.0, 1.28]
const RAMP_SECONDS: Array[float] = [105.0, 75.0, 52.0]
const MAX_RAMP: Array[float] = [0.78, 1.2, 1.5]

var state := State.START
var selected_difficulty := Difficulty.CLASSIC
var score := 0
var lives := 3
var combo := 0
var high_score := 0
var elapsed := 0.0
var last_slice_time := -10.0

func start_run(difficulty_level: int = Difficulty.CLASSIC) -> void:
	selected_difficulty = clampi(difficulty_level, Difficulty.BREEZY, Difficulty.FRENZY)
	state = State.PLAYING
	score = 0
	lives = 3
	combo = 0
	elapsed = 0.0
	last_slice_time = -10.0
	state_changed.emit(state)
	_emit_hud()


func record_slice(base_points: int) -> void:
	if state != State.PLAYING:
		return
	if elapsed - last_slice_time <= 0.7:
		combo += 1
	else:
		combo = 1
	last_slice_time = elapsed
	var multiplier := 1 + (combo - 1) / 3
	score += base_points * multiplier
	high_score = maxi(high_score, score)
	_emit_hud()


func record_miss() -> void:
	if state != State.PLAYING:
		return
	lives -= 1
	combo = 0
	_emit_hud()
	if lives <= 0:
		end_run()


func end_run() -> void:
	if state != State.PLAYING:
		return
	state = State.GAME_OVER
	high_score = maxi(high_score, score)
	state_changed.emit(state)
	_emit_hud()


func _process(delta: float) -> void:
	if state == State.PLAYING:
		elapsed += delta
		if combo > 0 and elapsed - last_slice_time > 1.0:
			combo = 0
			_emit_hud()


func difficulty() -> float:
	var base := BASE_PRESSURE[selected_difficulty]
	var ramp := minf(elapsed / RAMP_SECONDS[selected_difficulty], MAX_RAMP[selected_difficulty])
	return base + ramp


func difficulty_name() -> String:
	return DIFFICULTY_NAMES[selected_difficulty]


func _emit_hud() -> void:
	hud_changed.emit(score, lives, combo, high_score)
