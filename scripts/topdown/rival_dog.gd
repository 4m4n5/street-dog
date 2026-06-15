extends CharacterBody2D

const GameSfxScript := preload("res://scripts/audio/game_sfx.gd")

enum State {
	IDLE,
	CHASE,
	WINDUP,
	ATTACK,
	RECOVER,
	STAGGER,
	DEAD,
}

@export var tuning: TopdownTuning = TopdownTuning.new()
@export var max_hp: int = 2
@export var body_color: Color = Color(0.18, 0.18, 0.17, 1.0)
@export var head_color: Color = Color(0.10, 0.10, 0.095, 1.0)
@export var shoulder_scale: float = 1.0

@onready var _visual: Node2D = $Visual
@onready var _body_rect: ColorRect = $Visual/Body
@onready var _shoulders_rect: ColorRect = $Visual/Shoulders
@onready var _head_rect: ColorRect = $Visual/Head
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _attack_hitbox: Area2D = $AttackHitbox
@onready var _attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var _telegraph: CanvasItem = $Visual/Telegraph
@onready var _health_fill: ColorRect = $HealthBar/Fill

var _state := State.IDLE
var _state_frames_remaining := 0
var _hp := 2
var _home_position := Vector2.ZERO
var _facing_direction := Vector2.LEFT
var _attack_direction := Vector2.LEFT
var _target_hit_this_bite := false
var _patrol_phase := 0.0
var _flash_tween: Tween
var _noise_aggro_until_msec := 0


func _ready() -> void:
	_ensure_tuning()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("rival_dog")
	add_to_group("hurtbox")
	_home_position = global_position
	_hp = max_hp
	_apply_visual_palette()
	_configure_attack_hitbox()
	_update_health_bar()
	_telegraph.visible = false
	_attack_hitbox.body_entered.connect(_on_attack_body_entered)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	match _state:
		State.IDLE:
			_process_idle(delta, player)
		State.CHASE:
			_process_chase(delta, player)
		State.WINDUP:
			_process_windup(delta)
		State.ATTACK:
			_process_attack()
		State.RECOVER:
			_process_recover(delta)
		State.STAGGER:
			_process_stagger(delta)

	move_and_slide()


func take_hit(damage: int = 1, knockback: Vector2 = Vector2.ZERO, hit_stop: float = 0.0) -> bool:
	if _state == State.DEAD or damage <= 0:
		return false

	_hp = maxi(_hp - damage, 0)
	_update_health_bar()
	_play_sfx(&"play_hit")

	if _hp <= 0:
		_die(knockback)
	else:
		_disable_attack_hitbox()
		_telegraph.visible = false
		velocity = knockback
		_enter_state(State.STAGGER, _get_stagger_frames(hit_stop))
		_flash_hit()

	return true


func _get_stagger_frames(hit_stop: float) -> int:
	var hit_stop_frames := int(ceilf(maxf(hit_stop, 0.0) * 60.0))
	return maxi(tuning.rival_stagger_frames, hit_stop_frames)


func alert_from_noise(source_position: Vector2, duration_sec: float = 2.0) -> void:
	if _state == State.DEAD:
		return
	_noise_aggro_until_msec = maxi(_noise_aggro_until_msec, Time.get_ticks_msec() + int(duration_sec * 1000.0))
	if _state == State.IDLE:
		_enter_state(State.CHASE, 0)


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = TopdownTuning.new()


func _apply_visual_palette() -> void:
	_body_rect.color = body_color
	_shoulders_rect.color = body_color.lightened(0.10)
	_shoulders_rect.scale = Vector2(shoulder_scale, 1.0)
	_head_rect.color = head_color
	_set_visual_rect_color("Snout", head_color.darkened(0.18))
	_set_visual_rect_color("EarL", head_color.darkened(0.08))
	_set_visual_rect_color("EarR", head_color.darkened(0.04))
	_set_visual_rect_color("Tail", head_color.darkened(0.02))
	for paw_name in ["PawLF", "PawRF", "PawLB", "PawRB"]:
		_set_visual_rect_color(paw_name, head_color.darkened(0.04))


func _set_visual_rect_color(node_name: StringName, color: Color) -> void:
	var rect := _visual.get_node_or_null(NodePath(node_name)) as ColorRect
	if rect != null:
		rect.color = color


func _process_idle(delta: float, player: Node2D) -> void:
	if _can_detect_player(player):
		_enter_state(State.CHASE, 0)
		return

	_patrol_phase += delta * 0.9
	var patrol_target := _home_position + Vector2(cos(_patrol_phase), sin(_patrol_phase * 0.7)) * tuning.rival_patrol_radius
	var direction := global_position.direction_to(patrol_target) if global_position.distance_to(patrol_target) > 8.0 else Vector2.ZERO
	_apply_direction(direction, tuning.rival_move_speed * tuning.rival_patrol_speed_mult, delta)


func _process_chase(delta: float, player: Node2D) -> void:
	if player == null:
		_enter_state(State.IDLE, 0)
		return

	var distance := global_position.distance_to(player.global_position)
	if distance > tuning.rival_detection_range * 1.35 and not _has_noise_aggro():
		_enter_state(State.IDLE, 0)
		return
	if distance <= tuning.rival_attack_range:
		_start_windup(player.global_position)
		return

	var chase_direction := global_position.direction_to(player.global_position)
	chase_direction = (chase_direction + _get_separation()).normalized()
	_apply_direction(chase_direction, tuning.rival_move_speed, delta)


func _process_windup(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, tuning.rival_recover_friction * delta)
	_face_direction(_attack_direction, delta)
	_telegraph.visible = true
	_telegraph.modulate.a = 0.62 if (int(Time.get_ticks_msec() / 90) % 2 == 0) else 1.0
	_tick_state_frame()
	if _state_frames_remaining <= 0:
		_enter_attack()


func _process_attack() -> void:
	velocity = _attack_direction * tuning.rival_attack_lunge_speed
	_update_attack_hitbox_transform()
	_tick_state_frame()
	if _state_frames_remaining <= 0:
		_enter_recover()


func _process_recover(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, tuning.rival_recover_friction * delta)
	_tick_state_frame()
	if _state_frames_remaining <= 0:
		_enter_state(State.CHASE, 0)


func _process_stagger(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, tuning.rival_recover_friction * delta)
	_tick_state_frame()
	if _state_frames_remaining <= 0:
		_enter_state(State.CHASE, 0)


func _start_windup(target_position: Vector2) -> void:
	_attack_direction = global_position.direction_to(target_position)
	if _attack_direction == Vector2.ZERO:
		_attack_direction = _facing_direction
	_face_direction(_attack_direction, 1.0)
	_update_attack_hitbox_transform()
	_enter_state(State.WINDUP, tuning.rival_windup_frames)


func _enter_attack() -> void:
	_target_hit_this_bite = false
	_telegraph.visible = false
	_enable_attack_hitbox(true)
	_tween_visual_scale(Vector2(1.18, 0.84), frames_to_seconds(tuning.rival_attack_frames))
	_enter_state(State.ATTACK, tuning.rival_attack_frames)


func _enter_recover() -> void:
	_disable_attack_hitbox()
	_tween_visual_scale(Vector2.ONE, frames_to_seconds(tuning.rival_recover_frames))
	_enter_state(State.RECOVER, tuning.rival_recover_frames)


func _enter_state(next_state: State, frames: int) -> void:
	_state = next_state
	_state_frames_remaining = maxi(frames, 0)
	if _state != State.WINDUP:
		_telegraph.visible = false
	if _state != State.ATTACK:
		_disable_attack_hitbox()


func _tick_state_frame() -> void:
	_state_frames_remaining = maxi(_state_frames_remaining - 1, 0)


func _apply_direction(direction: Vector2, speed: float, delta: float) -> void:
	if direction != Vector2.ZERO:
		_facing_direction = direction.normalized()
		_face_direction(_facing_direction, delta)
		velocity = _facing_direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, tuning.rival_recover_friction * delta)


func _face_direction(direction: Vector2, delta: float) -> void:
	if direction.length_squared() <= 0.01:
		return
	_visual.rotation = lerp_angle(_visual.rotation, direction.angle(), tuning.rotation_lerp_speed * delta)


func _can_detect_player(player: Node2D) -> bool:
	return player != null and global_position.distance_to(player.global_position) <= tuning.rival_detection_range


func _has_noise_aggro() -> bool:
	return Time.get_ticks_msec() <= _noise_aggro_until_msec


func _get_separation() -> Vector2:
	var steering := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("rival_dog"):
		if other == self or not (other is Node2D):
			continue
		var other_node := other as Node2D
		var offset := global_position - other_node.global_position
		var distance := offset.length()
		if distance > 0.0 and distance < tuning.rival_separation_radius:
			steering += offset.normalized() * ((tuning.rival_separation_radius - distance) / tuning.rival_separation_radius)
	return steering * tuning.rival_separation_force / maxf(tuning.rival_move_speed, 1.0)


func _configure_attack_hitbox() -> void:
	var shape := _attack_shape.shape as RectangleShape2D
	if shape != null:
		shape.size = tuning.rival_attack_hitbox_size
	_update_attack_hitbox_transform()
	_disable_attack_hitbox()


func _update_attack_hitbox_transform() -> void:
	_attack_hitbox.position = _attack_direction * tuning.rival_attack_hitbox_offset
	_attack_hitbox.rotation = _attack_direction.angle()
	var shape := _attack_shape.shape as RectangleShape2D
	if shape != null:
		shape.size = tuning.rival_attack_hitbox_size


func _enable_attack_hitbox(enabled: bool) -> void:
	_attack_hitbox.set_deferred("monitoring", enabled)
	_attack_shape.set_deferred("disabled", not enabled)


func _disable_attack_hitbox() -> void:
	_enable_attack_hitbox(false)


func _on_attack_body_entered(body: Node) -> void:
	if _state != State.ATTACK or _target_hit_this_bite or not body.is_in_group("player"):
		return
	if not body.has_method("receive_enemy_hit"):
		return
	_target_hit_this_bite = true
	var knockback := _attack_direction * tuning.rival_bite_knockback
	body.call("receive_enemy_hit", tuning.rival_contact_damage, knockback, self)


func _update_health_bar() -> void:
	if _health_fill == null:
		return
	var ratio := float(_hp) / float(maxi(max_hp, 1))
	_health_fill.scale.x = clampf(ratio, 0.0, 1.0)


func _flash_hit() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()
	_visual.modulate = Color(1.0, 0.48, 0.38, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(_visual, "modulate", Color.WHITE, 0.12)


func _die(knockback: Vector2) -> void:
	_enter_state(State.DEAD, 0)
	velocity = knockback
	_collision_shape.set_deferred("disabled", true)
	_disable_attack_hitbox()
	_play_sfx(&"play_enemy_defeat")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	await tween.finished
	queue_free()


func _tween_visual_scale(target_scale: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_visual, "scale", target_scale, maxf(duration, 0.01))


func _play_sfx(method_name: StringName) -> void:
	var sfx := GameSfxScript.instance()
	if sfx != null and sfx.has_method(method_name):
		sfx.call(method_name)


func frames_to_seconds(frame_count: int) -> float:
	return float(maxi(frame_count, 1)) / 60.0
