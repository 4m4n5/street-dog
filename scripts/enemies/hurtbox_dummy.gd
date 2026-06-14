extends StaticBody2D
class_name HurtboxDummy

## Solid Mumbai street prop — blocks the player, takes bites, breaks after max_hits.

enum PropStyle { CRATE, SACK, CONE, BIN }

@export var max_hits: int = 5
@export var knockback_decay: float = 820.0
@export var prop_style: PropStyle = PropStyle.CRATE

@onready var _visual: Node2D = $Visual
@onready var _body: ColorRect = $Visual/Body
@onready var _top: ColorRect = $Visual/Top
@onready var _crack: Line2D = $Visual/Crack
@onready var _hp_pips: Node2D = $Visual/HpPips

var _hits_remaining: int = 5
var _knockback_velocity := Vector2.ZERO
var _flash_tween: Tween
var _destroying := false


func _ready() -> void:
	add_to_group("enemy")
	_hits_remaining = max_hits
	_apply_style()
	_update_damage_visual()


func _physics_process(delta: float) -> void:
	if _knockback_velocity.length_squared() <= 1.0:
		_knockback_velocity = Vector2.ZERO
		return

	global_position += _knockback_velocity * delta
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)


func take_hit(knockback: Vector2, _hit_stop: bool) -> void:
	if _destroying or _hits_remaining <= 0:
		return

	_hits_remaining -= 1
	_knockback_velocity = knockback
	_flash()
	_shake_visual()
	_update_damage_visual()
	GameSfx.play_hit()

	if _hits_remaining <= 0:
		_destroy()


func _apply_style() -> void:
	match prop_style:
		PropStyle.CRATE:
			_body.size = Vector2(36.0, 30.0)
			_body.position = Vector2(-18.0, -10.0)
			_body.color = Color(0.72, 0.36, 0.12, 1.0)
			_top.size = Vector2(40.0, 8.0)
			_top.position = Vector2(-20.0, -18.0)
			_top.color = Color(0.58, 0.28, 0.08, 1.0)
		PropStyle.SACK:
			_body.size = Vector2(34.0, 26.0)
			_body.position = Vector2(-17.0, -8.0)
			_body.color = Color(0.12, 0.46, 0.18, 1.0)
			_top.size = Vector2(30.0, 10.0)
			_top.position = Vector2(-15.0, -16.0)
			_top.color = Color(0.1, 0.38, 0.14, 1.0)
		PropStyle.CONE:
			_body.size = Vector2(22.0, 28.0)
			_body.position = Vector2(-11.0, -6.0)
			_body.color = Color(0.82, 0.22, 0.06, 1.0)
			_top.size = Vector2(26.0, 6.0)
			_top.position = Vector2(-13.0, -12.0)
			_top.color = Color(0.92, 0.88, 0.72, 1.0)
		PropStyle.BIN:
			_body.size = Vector2(32.0, 34.0)
			_body.position = Vector2(-16.0, -12.0)
			_body.color = Color(0.03, 0.27, 0.12, 1.0)
			_top.size = Vector2(36.0, 7.0)
			_top.position = Vector2(-18.0, -18.0)
			_top.color = Color(0.06, 0.36, 0.16, 1.0)


func _update_damage_visual() -> void:
	var damage_ratio := 1.0 - float(_hits_remaining) / float(max_hits)
	_visual.modulate = Color.WHITE.lerp(Color(0.72, 0.58, 0.55, 1.0), damage_ratio)
	_crack.visible = damage_ratio > 0.15
	_crack.modulate.a = clampf(damage_ratio * 1.2, 0.0, 1.0)

	for i in range(_hp_pips.get_child_count()):
		var pip := _hp_pips.get_child(i) as ColorRect
		if pip:
			pip.visible = i < _hits_remaining


func _flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_visual.modulate = Color(1.55, 1.2, 1.0, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.04)
	_flash_tween.tween_callback(_update_damage_visual)


func _shake_visual() -> void:
	var base := _visual.position
	var tween := create_tween()
	tween.tween_property(_visual, "position", base + Vector2(3.0, 0.0), 0.03)
	tween.tween_property(_visual, "position", base + Vector2(-2.0, 1.0), 0.03)
	tween.tween_property(_visual, "position", base, 0.04)


func _destroy() -> void:
	_destroying = true
	GameSfx.play_prop_break()
	collision_layer = 0
	$BodyCollider.set_deferred("disabled", true)
	$Hurtbox.set_deferred("monitoring", false)
	$Hurtbox.set_deferred("monitorable", false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "scale", Vector2(1.15, 0.35), 0.14)
	tween.tween_property(_visual, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(queue_free)
