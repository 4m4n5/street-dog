extends CharacterBody2D

const PlayerConstants = preload("res://scripts/player/player_constants.gd")
const PlayerHealthScript = preload("res://scripts/player/player_health.gd")

enum State {
	MOVE,
	PARRY,
	ATTACK_STARTUP,
	ATTACK_ACTIVE,
	ATTACK_RECOVERY,
	HITSTUN,
}

@export var speed: float = PlayerConstants.MOVE_SPEED
@export var ground_accel: float = PlayerConstants.GROUND_ACCEL
@export var jump_velocity: float = PlayerConstants.JUMP_VELOCITY
@export var coyote_time: float = PlayerConstants.COYOTE_TIME
@export var jump_buffer_time: float = PlayerConstants.JUMP_BUFFER_TIME
@export var rise_gravity_mult: float = PlayerConstants.RISE_GRAVITY_MULT
@export var fall_gravity_mult: float = PlayerConstants.FALL_GRAVITY_MULT
@export var jump_cut_mult: float = PlayerConstants.JUMP_CUT_MULT
@export var attack_startup_frames: int = PlayerConstants.ATTACK_STARTUP_FRAMES
@export var attack_active_frames: int = PlayerConstants.ATTACK_ACTIVE_FRAMES
@export var attack_recovery_frames: int = PlayerConstants.ATTACK_RECOVERY_FRAMES
@export var attack_recovery_move_unlock_frame: int = PlayerConstants.ATTACK_RECOVERY_MOVE_UNLOCK_FRAME
@export var attack_startup_speed_mult: float = PlayerConstants.ATTACK_STARTUP_SPEED_MULT
@export var attack_lunge_speed: float = PlayerConstants.ATTACK_LUNGE_SPEED
@export var attack_hitbox_forward_offset: float = PlayerConstants.ATTACK_HITBOX_FORWARD_OFFSET
@export var attack_knockback_speed: float = PlayerConstants.ATTACK_KNOCKBACK_SPEED
@export var attack_self_knockback_speed: float = PlayerConstants.ATTACK_SELF_KNOCKBACK_SPEED
@export var attack_hit_stop_time: float = PlayerConstants.ATTACK_HIT_STOP_TIME
@export var parry_frames: int = PlayerConstants.PARRY_FRAMES
@export var hitstun_frames: int = PlayerConstants.HITSTUN_FRAMES
@export var invuln_time: float = PlayerConstants.INVULN_TIME
@export var camera_look_ahead: float = 72.0

@onready var _visual: Node2D = $Visual
@onready var _camera: Camera2D = $Camera2D
@onready var _head: Control = $Visual/Head
@onready var _snout: Control = $Visual/Snout
@onready var _health: PlayerHealthScript = $PlayerHealth
@onready var _attack_hitbox: Area2D = get_node_or_null("AttackHitbox") as Area2D

var _state := State.MOVE
var _state_frames_left := 0
var _coyote_timer := 0.0
var _jump_buffer_timer := 0.0
var _invuln_timer := 0.0
var _facing_direction := 1
var _attack_direction := 1
var _hit_targets: Array[Node] = []
var _attack_hit_connected := false
var _hit_stop_active := false
var _head_base_position := Vector2.ZERO
var _snout_base_position := Vector2.ZERO
var _pose_tween: Tween
var _respawning := false


func _ready() -> void:
	_head_base_position = _head.position
	_snout_base_position = _snout.position
	if _attack_hitbox != null:
		_attack_hitbox.monitoring = false
		_attack_hitbox.position.x = attack_hitbox_forward_offset
		if not _attack_hitbox.area_entered.is_connected(_on_attack_hitbox_area_entered):
			_attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
	if _health != null and not _health.died.is_connected(_on_health_died):
		_health.died.connect(_on_health_died)


func _physics_process(delta: float) -> void:
	if _respawning:
		return

	var was_on_floor := is_on_floor()
	_update_jump_timers(delta)
	_invuln_timer = maxf(_invuln_timer - delta, 0.0)
	_update_invuln_flash()

	if _state == State.MOVE:
		if Input.is_action_just_pressed("parry") and _can_parry():
			_enter_parry()
		elif Input.is_action_just_pressed("attack") and _can_start_attack():
			_enter_attack_startup()

	_apply_state(delta)
	_apply_gravity(delta)
	_update_camera_look_ahead(Input.get_axis("move_left", "move_right"), delta)
	move_and_slide()

	if not was_on_floor and is_on_floor() and _state == State.MOVE:
		_play_land_squash()
		GameSfx.play_land()


func _update_jump_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = coyote_time
	else:
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_mult


func _apply_state(delta: float) -> void:
	match _state:
		State.MOVE:
			_try_consume_jump()
			_apply_horizontal_input(delta, 1.0, true)
		State.PARRY:
			velocity.x = move_toward(velocity.x, 0.0, ground_accel * delta)
			_tick_timed_state(State.MOVE, 0)
		State.ATTACK_STARTUP:
			_apply_attack_startup(delta)
		State.ATTACK_ACTIVE:
			_apply_attack_active()
		State.ATTACK_RECOVERY:
			_apply_attack_recovery(delta)
		State.HITSTUN:
			velocity.x = move_toward(velocity.x, 0.0, ground_accel * delta)
			_tick_timed_state(State.MOVE, 0)


func _try_consume_jump() -> void:
	if _jump_buffer_timer <= 0.0 or _coyote_timer <= 0.0:
		return
	velocity.y = jump_velocity
	_jump_buffer_timer = 0.0
	_coyote_timer = 0.0
	GameSfx.play_jump()


func _apply_horizontal_input(delta: float, speed_mult: float, allow_facing_update: bool) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * speed * speed_mult
	velocity.x = move_toward(velocity.x, target_speed, ground_accel * delta)

	if allow_facing_update and direction != 0.0:
		_set_facing(int(signf(direction)))


func _apply_attack_startup(delta: float) -> void:
	_apply_horizontal_input(delta, attack_startup_speed_mult, false)
	_tick_attack_phase(State.ATTACK_ACTIVE, attack_active_frames)


func _apply_attack_active() -> void:
	if not _attack_hit_connected:
		velocity.x = float(_attack_direction) * attack_lunge_speed
		_check_overlapping_hurtboxes()
	_tick_attack_phase(State.ATTACK_RECOVERY, attack_recovery_frames)


func _apply_attack_recovery(delta: float) -> void:
	var recovery_frame := attack_recovery_frames - _state_frames_left + 1
	if recovery_frame >= attack_recovery_move_unlock_frame:
		_apply_horizontal_input(delta, 1.0, false)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_accel * delta)
	_tick_attack_phase(State.MOVE, 0)


func _tick_attack_phase(next_state: State, next_frames: int) -> void:
	_state_frames_left -= 1
	if _state_frames_left > 0:
		return

	match next_state:
		State.ATTACK_ACTIVE:
			_enter_attack_active()
		State.ATTACK_RECOVERY:
			_enter_attack_recovery()
		State.MOVE:
			_enter_move()
		_:
			_state = next_state
			_state_frames_left = next_frames


func _tick_timed_state(next_state: State, next_frames: int) -> void:
	_state_frames_left -= 1
	if _state_frames_left > 0:
		return
	_state = next_state
	_state_frames_left = next_frames
	if next_state == State.MOVE:
		_reset_visual_pose(0.06)


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return

	var gravity_mult := fall_gravity_mult if velocity.y > 0.0 else rise_gravity_mult
	velocity += get_gravity() * gravity_mult * delta


func _can_start_attack() -> bool:
	return _state == State.MOVE and is_on_floor()


func _can_parry() -> bool:
	return _state == State.MOVE and is_on_floor()


func is_parrying() -> bool:
	return _state == State.PARRY


func receive_enemy_hit(damage: int, knockback: Vector2, attacker: Node) -> void:
	if _respawning:
		return
	if _state == State.PARRY:
		_resolve_parry(attacker)
		return
	if _invuln_timer > 0.0:
		return
	if _health == null or not _health.take_damage(damage):
		return

	GameSfx.play_hurt()
	_invuln_timer = invuln_time
	_enter_hitstun(knockback)


func _resolve_parry(attacker: Node) -> void:
	GameSfx.play_parry()
	_start_hit_stop()
	if attacker != null and attacker.has_method("on_parried"):
		attacker.call("on_parried")
	_enter_move()


func _enter_parry() -> void:
	_state = State.PARRY
	_state_frames_left = parry_frames
	_kill_pose_tween()
	_visual.modulate = Color(0.72, 0.95, 1.18, 1.0)
	_snout.modulate = Color(0.85, 1.2, 1.35, 1.0)


func _enter_hitstun(knockback: Vector2) -> void:
	_state = State.HITSTUN
	_state_frames_left = hitstun_frames
	velocity = knockback
	_set_hitbox_enabled(false)
	_kill_pose_tween()
	_visual.modulate = Color(1.35, 0.72, 0.68, 1.0)


func _enter_attack_startup() -> void:
	_state = State.ATTACK_STARTUP
	_state_frames_left = attack_startup_frames
	_attack_direction = _facing_direction
	_attack_hit_connected = false
	_hit_targets.clear()
	_set_hitbox_enabled(false)
	_play_attack_pose(Vector2(0.92, 0.88), 0.035, 0.0)


func _enter_attack_active() -> void:
	_state = State.ATTACK_ACTIVE
	_state_frames_left = attack_active_frames
	_set_hitbox_enabled(true)
	_play_attack_pose(Vector2(1.15, 0.92), 0.025, 10.0)
	GameSfx.play_bite()


func _enter_attack_recovery() -> void:
	_state = State.ATTACK_RECOVERY
	_state_frames_left = attack_recovery_frames
	_set_hitbox_enabled(false)
	_play_attack_pose(Vector2(0.98, 1.02), 0.05, 0.0)


func _enter_move() -> void:
	_state = State.MOVE
	_state_frames_left = 0
	_set_hitbox_enabled(false)
	_reset_visual_pose(0.08)


func _set_facing(direction: int) -> void:
	if direction == 0:
		return
	_facing_direction = direction
	_visual.scale.x = absf(_visual.scale.x) * float(_facing_direction)


func _set_hitbox_enabled(enabled: bool) -> void:
	if _attack_hitbox == null:
		return
	_attack_hitbox.position.x = attack_hitbox_forward_offset * float(_attack_direction)
	_attack_hitbox.set_deferred("monitoring", enabled)


func _check_overlapping_hurtboxes() -> void:
	if _attack_hitbox == null or not _attack_hitbox.monitoring:
		return
	for area in _attack_hitbox.get_overlapping_areas():
		_try_hit_area(area)


func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	if _state != State.ATTACK_ACTIVE:
		return
	_try_hit_area(area)


func _try_hit_area(area: Area2D) -> void:
	if area == null:
		return

	var target := area.get_parent()
	if target == null:
		return
	if not area.is_in_group("hurtbox") and not target.is_in_group("enemy"):
		return
	if _hit_targets.has(target):
		return

	_hit_targets.append(target)
	_attack_hit_connected = true
	if target.has_method("take_hit"):
		target.call("take_hit", Vector2(float(_attack_direction) * attack_knockback_speed, -20.0), true)
	velocity.x = -float(_attack_direction) * attack_self_knockback_speed
	_set_hitbox_enabled(false)
	_start_hit_stop()


func _start_hit_stop() -> void:
	if _hit_stop_active or attack_hit_stop_time <= 0.0:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(attack_hit_stop_time, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


func _update_invuln_flash() -> void:
	if _invuln_timer <= 0.0 or _state == State.PARRY:
		return
	var flash_on := int(_invuln_timer * 24.0) % 2 == 0
	_visual.modulate.a = 1.0 if flash_on else 0.45


func _on_health_died() -> void:
	if _respawning:
		return
	_respawn_after_death()


func _respawn_after_death() -> void:
	_respawning = true
	_set_hitbox_enabled(false)
	velocity = Vector2.ZERO

	var tween := create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, 0.35)
	await tween.finished
	await get_tree().create_timer(0.45).timeout

	var level := get_tree().current_scene.get_node_or_null("StreetNight")
	if level != null and level.has_node("Spawn"):
		global_position = level.get_node("Spawn").global_position

	if _health != null:
		_health.current_health = _health.max_health
		_health.health_changed.emit(_health.current_health, _health.max_health)

	_visual.modulate = Color.WHITE
	_enter_move()
	_respawning = false


func _play_attack_pose(scale_abs: Vector2, duration: float, snout_offset_x: float) -> void:
	_kill_pose_tween()
	_pose_tween = create_tween()
	_pose_tween.set_parallel(true)
	_pose_tween.tween_property(_visual, "scale", Vector2(scale_abs.x * float(_attack_direction), scale_abs.y), duration)
	_pose_tween.tween_property(_head, "position", _head_base_position + Vector2(snout_offset_x * 0.45, 0.0), duration)
	_pose_tween.tween_property(_snout, "position", _snout_base_position + Vector2(snout_offset_x, 0.0), duration)
	_pose_tween.tween_property(_snout, "modulate", Color(1.25, 1.08, 0.86, 1.0), duration)


func _reset_visual_pose(duration: float) -> void:
	_kill_pose_tween()
	_pose_tween = create_tween()
	_pose_tween.set_parallel(true)
	_pose_tween.tween_property(_visual, "scale", Vector2(float(_facing_direction), 1.0), duration)
	_pose_tween.tween_property(_head, "position", _head_base_position, duration)
	_pose_tween.tween_property(_snout, "position", _snout_base_position, duration)
	_pose_tween.tween_property(_snout, "modulate", Color.WHITE, duration)
	_pose_tween.tween_property(_visual, "modulate", Color.WHITE, duration)


func _play_land_squash() -> void:
	_kill_pose_tween()
	_visual.scale = Vector2(1.08 * float(_facing_direction), 0.9)
	_reset_visual_pose(0.12)


func _kill_pose_tween() -> void:
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()


func _update_camera_look_ahead(direction: float, delta: float) -> void:
	if _camera == null:
		return
	var target_x := camera_look_ahead * direction
	_camera.offset.x = lerpf(_camera.offset.x, target_x, 1.0 - exp(-8.0 * delta))
