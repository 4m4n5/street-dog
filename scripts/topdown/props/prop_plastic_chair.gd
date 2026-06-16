extends TopdownProp

@export var kick_distance: float = 180.0
@export var slide_time: float = 0.42
@export var settle_delay: float = 1.5
@export var rival_stagger_frames: int = 8
@export var rival_stagger_knockback: float = 110.0

var _sliding := false
var _kick_direction := Vector2.RIGHT
var _staggered_targets: Dictionary = {}
@onready var _stagger_area: Area2D = get_node_or_null("StaggerArea") as Area2D


func _ready() -> void:
	prop_kind = &"plastic_chair"
	cover_tier = &"low"
	super._ready()
	if _stagger_area != null:
		_stagger_area.body_entered.connect(_on_stagger_area_body_entered)
	_set_stagger_area_enabled(false)
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if not _sliding or _stagger_area == null:
		return
	for body in _stagger_area.get_overlapping_bodies():
		_try_stagger_rival(body)


func on_bite_hit(biter: Node2D, direction: Vector2, damage: int) -> void:
	if _sliding:
		return
	_sliding = true
	_kick_direction = _safe_direction(direction)
	_staggered_targets.clear()
	_play_sfx(&"play_hit")
	_flash_hit(Color(0.62, 0.82, 0.92, 1.0))
	_set_stagger_area_enabled(true)
	set_physics_process(true)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", global_position + _kick_direction * kick_distance, slide_time)
	await tween.finished
	_set_stagger_area_enabled(false)
	set_physics_process(false)
	await get_tree().create_timer(settle_delay).timeout
	_sliding = false


func _on_stagger_area_body_entered(body: Node) -> void:
	_try_stagger_rival(body)


func _try_stagger_rival(body: Node) -> void:
	if not _sliding or body == null or not body.is_in_group("rival_dog"):
		return
	if body.has_method("is_dead") and body.call("is_dead"):
		return
	var target_id := body.get_instance_id()
	if _staggered_targets.has(target_id):
		return
	_staggered_targets[target_id] = true
	if body.has_method("apply_stagger"):
		body.call("apply_stagger", rival_stagger_frames, _kick_direction * rival_stagger_knockback)


func _set_stagger_area_enabled(enabled: bool) -> void:
	if _stagger_area == null:
		return
	_stagger_area.set_deferred("monitoring", enabled)
	var shape := _stagger_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", not enabled)
