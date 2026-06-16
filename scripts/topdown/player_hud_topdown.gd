extends CanvasLayer

@export var tuning: TopdownTuning = TopdownTuning.new()

@onready var _pips: HBoxContainer = $Root/HPRow/Pips
@onready var _label: Label = $Root/HPRow/Label

var _health: PlayerHealthTopdown


func _ready() -> void:
	_ensure_tuning()
	call_deferred("_bind_player_health")


func _bind_player_health() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_draw_pips(tuning.player_max_hp, tuning.player_max_hp)
		return

	_health = player.get_node_or_null(^"PlayerHealthTopdown") as PlayerHealthTopdown
	if _health == null:
		_draw_pips(tuning.player_max_hp, tuning.player_max_hp)
		return

	if not _health.health_changed.is_connected(_on_health_changed):
		_health.health_changed.connect(_on_health_changed)
	_on_health_changed(_health.current_hp, _health.max_hp)


func _on_health_changed(current: int, maximum: int) -> void:
	_draw_pips(current, maximum)


func _draw_pips(current: int, maximum: int) -> void:
	_label.text = "HP"
	for child in _pips.get_children():
		child.queue_free()
	for i in range(maxi(maximum, 0)):
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(26.0, 14.0)
		pip.color = Color(0.9, 0.28, 0.18, 1.0) if i < current else Color(0.16, 0.055, 0.05, 0.82)
		_pips.add_child(pip)


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = TopdownTuning.new()
