extends Node
class_name PlayerHealthTopdown

signal health_changed(current: int, maximum: int)
signal died
signal invulnerability_changed(enabled: bool)

@export var tuning: TopdownTuning = TopdownTuning.new()

var current_hp: int
var max_hp: int

var _invuln_time_remaining := 0.0


func _ready() -> void:
	_ensure_tuning()
	reset_full(false)


func _process(delta: float) -> void:
	if _invuln_time_remaining <= 0.0:
		return
	_invuln_time_remaining = maxf(_invuln_time_remaining - delta, 0.0)
	if _invuln_time_remaining <= 0.0:
		invulnerability_changed.emit(false)


func take_damage(amount: int = 1) -> bool:
	if amount <= 0 or is_invulnerable() or current_hp <= 0:
		return false
	current_hp = maxi(current_hp - amount, 0)
	health_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		died.emit()
	else:
		_set_invulnerable(tuning.player_invuln_sec)
	return true


func reset_full(grant_invuln: bool = true) -> void:
	_ensure_tuning()
	max_hp = tuning.player_max_hp
	current_hp = max_hp if tuning.respawn_full_hp else maxi(current_hp, 1)
	health_changed.emit(current_hp, max_hp)
	_set_invulnerable(tuning.player_invuln_sec if grant_invuln else 0.0)


func is_invulnerable() -> bool:
	return _invuln_time_remaining > 0.0


func is_alive() -> bool:
	return current_hp > 0


func _set_invulnerable(duration: float) -> void:
	var was_invulnerable := is_invulnerable()
	_invuln_time_remaining = maxf(duration, 0.0)
	if was_invulnerable != is_invulnerable():
		invulnerability_changed.emit(is_invulnerable())


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = TopdownTuning.new()
