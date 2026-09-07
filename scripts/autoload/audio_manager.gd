class_name AudioManager
extends Node

var players: Array[AudioStreamPlayer] = []
var next_player := 0
var slice_sound: AudioStreamWAV
var danger_sound: AudioStreamWAV

func _ready() -> void:
	for index in 6:
		var player := AudioStreamPlayer.new()
		player.name = "OneShot%d" % index
		add_child(player)
		players.append(player)
	slice_sound = _make_tone(720.0, 0.085, 0.32)
	danger_sound = _make_tone(105.0, 0.32, 0.5)


func play_slice() -> void:
	_play(slice_sound, randf_range(0.88, 1.12))


func play_danger() -> void:
	_play(danger_sound, 1.0)


func _play(stream: AudioStream, pitch: float) -> void:
	var player := players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


func _make_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(duration * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in sample_count:
		var time := float(index) / float(sample_rate)
		var envelope := 1.0 - float(index) / float(sample_count)
		var overtone := sin(TAU * frequency * 2.03 * time) * 0.22
		var value := (sin(TAU * frequency * time) + overtone) * envelope * volume
		var sample := int(clampf(value, -1.0, 1.0) * 32767.0)
		bytes[index * 2] = sample & 0xff
		bytes[index * 2 + 1] = (sample >> 8) & 0xff
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = sample_rate
	wave.stereo = false
	wave.data = bytes
	return wave

