extends Node
class_name GameSfxManager

## Procedural blockout SFX — replace clips in assets/audio/ when art pass lands.

var _players: Array[AudioStreamPlayer] = []
var _next_player := 0


static func instance() -> GameSfxManager:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		return (tree as SceneTree).root.get_node(^"GameSfx") as GameSfxManager
	return null


func _ready() -> void:
	for i in 4:
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_players.append(player)


func play_bite() -> void:
	_play_tone(180.0, 0.07, 0.28, true)


func play_bite_whiff() -> void:
	_play_tone(150.0, 0.045, 0.12, false)


func play_hit() -> void:
	_play_tone(95.0, 0.09, 0.34, false)


func play_parry() -> void:
	_play_tone(420.0, 0.05, 0.3, true)
	_play_tone(280.0, 0.08, 0.18, true)


func play_hurt() -> void:
	_play_tone(140.0, 0.12, 0.36, false)


func play_prop_break() -> void:
	_play_tone(70.0, 0.14, 0.32, false)


func play_enemy_defeat() -> void:
	_play_tone(110.0, 0.16, 0.3, false)


func play_gully_clear() -> void:
	_play_tone(260.0, 0.08, 0.20, true)
	_play_tone(390.0, 0.10, 0.16, true)


func play_jump() -> void:
	_play_tone(260.0, 0.05, 0.14, true)


func play_land() -> void:
	_play_tone(120.0, 0.04, 0.12, false)


func _play_tone(freq: float, duration: float, volume: float, rising: bool) -> void:
	var player := _get_player()
	player.stream = _make_tone(freq, duration, volume, rising)
	player.pitch_scale = randf_range(0.94, 1.06)
	player.play()


func _get_player() -> AudioStreamPlayer:
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	return player


func _make_tone(freq: float, duration: float, volume: float, rising: bool) -> AudioStreamWAV:
	var sample_rate := 22050
	var frame_count := maxi(int(sample_rate * duration), 1)
	var data := PackedByteArray()
	data.resize(frame_count)

	for i in frame_count:
		var t := float(i) / float(sample_rate)
		var env := 1.0 - (t / duration)
		env *= env
		var sweep := freq * (1.15 if rising and t < duration * 0.35 else 1.0)
		var sample := sin(t * sweep * TAU) * env * volume
		data[i] = int(clampf((sample * 0.5 + 0.5) * 255.0, 0.0, 255.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
