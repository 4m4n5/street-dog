extends CanvasLayer

const PlayerHealthScript = preload("res://scripts/player/player_health.gd")

@onready var _hp_fill: ColorRect = $Margin/Panel/VBox/HpBar/Fill
@onready var _hp_label: Label = $Margin/Panel/VBox/HpLabel


func _ready() -> void:
	call_deferred("_bind_player")


func _bind_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var health := player.get_node_or_null("PlayerHealth") as PlayerHealthScript
	if health == null:
		return
	if not health.health_changed.is_connected(_on_health_changed):
		health.health_changed.connect(_on_health_changed)
	if not health.died.is_connected(_on_player_died):
		health.died.connect(_on_player_died)
	_on_health_changed(health.current_health, health.max_health)


func _on_health_changed(current: int, maximum: int) -> void:
	var ratio := 0.0 if maximum <= 0 else float(current) / float(maximum)
	_hp_fill.size.x = maxf(4.0, 196.0 * ratio)
	if ratio > 0.55:
		_hp_fill.color = Color(0.35, 0.78, 0.48, 1.0)
	elif ratio > 0.25:
		_hp_fill.color = Color(0.82, 0.62, 0.18, 1.0)
	else:
		_hp_fill.color = Color(0.82, 0.28, 0.22, 1.0)
	_hp_label.text = "HP %d / %d" % [current, maximum]


func _on_player_died() -> void:
	_hp_label.text = "KO — reload scene"
