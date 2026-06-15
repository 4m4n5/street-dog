extends CharacterBody2D

const GameSfxScript := preload("res://scripts/audio/game_sfx.gd")

enum State {
	MOVE,
	ATTACK_STARTUP,
	ATTACK_ACTIVE,
	ATTACK_RECOVERY,
	HITSTUN,
}

@export var tuning: TopdownTuning = TopdownTuning.new()

@onready var _visual: Node2D = $Visual
@onready var _body_shape: CollisionShape2D = $CollisionShape2D
@onready var _attack_hitbox: Area2D = $AttackHitbox
@onready var _attack_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var _health: PlayerHealthTopdown = $PlayerHealthTopdown
@onready var _camera: Camera2D = $Camera2D
@onready var _snout: CanvasItem = $Visual/Snout

var _state := State.MOVE
var _last_move_direction := Vector2.RIGHT
var _facing_direction := Vector2.RIGHT
var _bite_direction := Vector2.RIGHT
var _state_frames_remaining := 0
var _hit_targets: Dictionary = {}
var _attack_tween: Tween
var _hit_stop_active := false
var _is_respawning := false
var _buffered_attack := false
var _buffered_attack_frames_remaining := 0
var _buffered_direction := Vector2.RIGHT
var _buffered_recovery_direct := false
var _attack_coyote_frames_remaining := 0
var _attack_connected := false
var _windup_telegraph: Polygon2D
var _snout_flash_tween: Tween
var _camera_nudge_tween: Tween
var _camera_rest_offset := Vector2.ZERO


func _ready() -> void:
	_ensure_tuning()
	if tuning == null:
		tuning = preload("res://resources/topdown/default_tuning.tres")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("player")
	_health.tuning = tuning
	_camera_rest_offset = _camera.offset
	_configure_attack_hitbox()
	_create_attack_fx_nodes()
	call_deferred("_configure_camera_limits")
	_attack_hitbox.body_entered.connect(_on_attack_body_entered)
	_attack_hitbox.area_entered.connect(_on_attack_area_entered)


func _physics_process(delta: float) -> void:
	if _is_respawning:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_invuln_visual()
		return

	if Input.is_action_just_pressed("attack"):
		_handle_attack_pressed()

	match _state:
		State.MOVE:
			_apply_move_state(delta)
		State.ATTACK_STARTUP:
			_process_attack_startup(delta)
		State.ATTACK_ACTIVE:
			_process_attack_active()
		State.ATTACK_RECOVERY:
			_process_attack_recovery(delta)
		State.HITSTUN:
			_process_hitstun(delta)
	_update_invuln_visual()
	_tick_attack_buffer()
	move_and_slide()


func _exit_tree() -> void:
	if _hit_stop_active:
		Engine.time_scale = 1.0


func get_facing_direction() -> Vector2:
	return _facing_direction


func receive_enemy_hit(damage: int, knockback: Vector2, attacker: Node = null) -> bool:
	if _is_respawning or _health == null:
		return false
	if not _health.take_damage(damage):
		return false

	_clear_attack_buffer()
	_disable_attack_hitbox()
	velocity = knockback
	_play_sfx(&"play_hurt")

	if _health.is_alive():
		_enter_state(State.HITSTUN, tuning.player_hitstun_frames)
		_flash_hit()
	else:
		_begin_respawn()

	return true


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = TopdownTuning.new()


func _apply_move_state(delta: float) -> void:
	var direction := _get_move_input()
	if direction != Vector2.ZERO:
		_attack_coyote_frames_remaining = tuning.attack_coyote_frames
		_last_move_direction = direction
		_facing_direction = direction
		_face_direction(direction, delta)
		velocity = velocity.move_toward(direction * tuning.move_speed, tuning.move_accel * delta)
	else:
		_attack_coyote_frames_remaining = maxi(_attack_coyote_frames_remaining - 1, 0)
		velocity = velocity.move_toward(Vector2.ZERO, tuning.move_friction * delta)


func _process_attack_startup(delta: float) -> void:
	_face_direction(_bite_direction, delta)
	var windup_speed := tuning.move_speed * tuning.attack_startup_speed_mult
	velocity = velocity.move_toward(_bite_direction * windup_speed, tuning.move_accel * delta)
	_tick_attack_frame()
	if _state_frames_remaining <= 0:
		_enter_attack_active()


func _process_attack_active() -> void:
	velocity = _bite_direction * tuning.attack_lunge_speed
	_update_attack_hitbox_transform()
	_tick_attack_frame()
	if _state_frames_remaining <= 0:
		_enter_attack_recovery()


func _process_attack_recovery(delta: float) -> void:
	var recovery_elapsed := tuning.attack_recovery_frames - _state_frames_remaining
	if recovery_elapsed >= tuning.attack_recovery_move_unlock:
		_apply_move_state(delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, tuning.move_friction * delta)
	_tick_attack_frame()
	if _state_frames_remaining <= 0:
		if _has_buffered_attack():
			_start_attack(_buffered_direction)
		else:
			_enter_state(State.MOVE, 0)


func _process_hitstun(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, tuning.move_friction * delta)
	_tick_attack_frame()
	if _state_frames_remaining <= 0:
		_enter_state(State.MOVE, 0)


func _handle_attack_pressed() -> void:
	var requested_direction := _choose_bite_direction()
	match _state:
		State.MOVE:
			_start_attack(requested_direction)
		State.ATTACK_RECOVERY:
			_buffer_attack(requested_direction)
		State.HITSTUN:
			_clear_attack_buffer()
		_:
			pass


func _start_attack(direction: Vector2 = Vector2.ZERO) -> void:
	_clear_attack_buffer()
	_bite_direction = direction.normalized() if direction != Vector2.ZERO else _choose_bite_direction()
	_last_move_direction = _bite_direction
	_facing_direction = _bite_direction
	_attack_connected = false
	_visual.rotation = _bite_direction.angle()
	_hit_targets.clear()
	_update_attack_hitbox_transform()
	_play_sfx(&"play_bite")
	_show_windup_telegraph()
	_tween_visual_scale(Vector2(0.9, 1.12), frames_to_seconds(tuning.attack_startup_frames))
	_enter_state(State.ATTACK_STARTUP, tuning.attack_startup_frames)


func _buffer_attack(direction: Vector2) -> void:
	_buffered_attack = true
	_buffered_attack_frames_remaining = tuning.attack_buffer_frames
	_buffered_direction = direction.normalized() if direction != Vector2.ZERO else _choose_bite_direction()
	_buffered_recovery_direct = _state_frames_remaining <= tuning.attack_recovery_buffer_frames


func _has_buffered_attack() -> bool:
	return _buffered_attack and (_buffered_attack_frames_remaining > 0 or _buffered_recovery_direct)


func _tick_attack_buffer() -> void:
	if not _buffered_attack:
		return
	_buffered_attack_frames_remaining = maxi(_buffered_attack_frames_remaining - 1, 0)
	if _buffered_attack_frames_remaining <= 0:
		if not _buffered_recovery_direct:
			_clear_attack_buffer()


func _clear_attack_buffer() -> void:
	_buffered_attack = false
	_buffered_attack_frames_remaining = 0
	_buffered_recovery_direct = false


func _enter_attack_active() -> void:
	_hide_windup_telegraph()
	_tween_visual_scale(Vector2(1.24, 0.82), frames_to_seconds(tuning.attack_active_frames))
	_enable_attack_hitbox(true)
	_enter_state(State.ATTACK_ACTIVE, tuning.attack_active_frames)


func _enter_attack_recovery() -> void:
	_disable_attack_hitbox()
	if not _attack_connected:
		_play_whiff_feedback()
	_tween_visual_scale(Vector2.ONE, frames_to_seconds(tuning.attack_recovery_frames))
	_enter_state(State.ATTACK_RECOVERY, tuning.attack_recovery_frames)


func _enter_state(next_state: State, frames: int) -> void:
	_state = next_state
	_state_frames_remaining = maxi(frames, 0)
	if _state != State.ATTACK_STARTUP:
		_hide_windup_telegraph()
	if _state == State.MOVE:
		_disable_attack_hitbox()
		_tween_visual_scale(Vector2.ONE, 0.08)


func _tick_attack_frame() -> void:
	_state_frames_remaining = maxi(_state_frames_remaining - 1, 0)


func _get_move_input() -> Vector2:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down", tuning.input_deadzone)
	if direction == Vector2.ZERO:
		return Vector2.ZERO
	if tuning.allow_diagonal:
		return direction.normalized()
	if absf(direction.x) >= absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))


func _choose_bite_direction() -> Vector2:
	var current_input := _get_move_input()
	if current_input != Vector2.ZERO:
		return current_input.normalized()
	if _attack_coyote_frames_remaining > 0 and _last_move_direction != Vector2.ZERO:
		return _last_move_direction.normalized()
	if _facing_direction != Vector2.ZERO:
		return _facing_direction.normalized()
	return Vector2.RIGHT


func _face_direction(direction: Vector2, delta: float) -> void:
	if direction.length_squared() <= 0.01:
		return
	_visual.rotation = lerp_angle(_visual.rotation, direction.angle(), tuning.rotation_lerp_speed * delta)


func _configure_attack_hitbox() -> void:
	var shape := _attack_shape.shape as RectangleShape2D
	if shape != null:
		shape.size = tuning.attack_hitbox_size
	_update_attack_hitbox_transform()
	_disable_attack_hitbox()


func _configure_camera_limits() -> void:
	if _camera == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var half := viewport_size * 0.5
	_camera.limit_left = int(half.x)
	_camera.limit_top = int(half.y)
	_camera.limit_right = int(tuning.arena_width - half.x)
	_camera.limit_bottom = int(tuning.arena_height - half.y)
	_camera.limit_smoothed = true


func _update_attack_hitbox_transform() -> void:
	_attack_hitbox.position = _bite_direction * tuning.attack_hitbox_offset
	_attack_hitbox.rotation = _bite_direction.angle()
	var shape := _attack_shape.shape as RectangleShape2D
	if shape != null:
		shape.size = tuning.attack_hitbox_size


func _enable_attack_hitbox(enabled: bool) -> void:
	_attack_hitbox.set_deferred("monitoring", enabled)
	_attack_shape.set_deferred("disabled", not enabled)


func _disable_attack_hitbox() -> void:
	_enable_attack_hitbox(false)


func _on_attack_body_entered(body: Node) -> void:
	_try_hit_target(body)


func _on_attack_area_entered(area: Area2D) -> void:
	_try_hit_target(area)


func _try_hit_target(target: Node) -> void:
	if _state != State.ATTACK_ACTIVE:
		return
	var prop_target := _resolve_interactable_target(target)
	if prop_target != null:
		_try_hit_prop(prop_target)
		return

	var damage_target := _resolve_damage_target(target)
	if damage_target == null or damage_target == self:
		return
	var target_id := damage_target.get_instance_id()
	if _hit_targets.has(target_id):
		return
	if not damage_target.has_method("take_hit"):
		return

	_hit_targets[target_id] = true
	var knockback := _bite_direction * tuning.attack_knockback_target
	damage_target.call("take_hit", 1, knockback, tuning.attack_hit_stop_sec)
	_attack_connected = true
	velocity -= _bite_direction * tuning.attack_self_knockback
	_play_sfx(&"play_hit")
	_play_connect_feedback(true)
	_start_hit_stop()


func _try_hit_prop(prop_target: Node) -> void:
	var target_id := prop_target.get_instance_id()
	if _hit_targets.has(target_id):
		return
	if not prop_target.has_method("on_bite_hit"):
		return

	_hit_targets[target_id] = true
	prop_target.call("on_bite_hit", self, _bite_direction, 1)
	_attack_connected = true
	velocity -= _bite_direction * (tuning.attack_self_knockback * 0.45)
	_play_connect_feedback(false)


func _resolve_damage_target(target: Node) -> Node:
	if target.is_in_group("hurtbox"):
		return target
	var parent := target.get_parent()
	if parent != null and parent.is_in_group("hurtbox"):
		return parent
	return target


func _resolve_interactable_target(target: Node) -> Node:
	if target.is_in_group("interactable_prop"):
		return target
	var parent := target.get_parent()
	if parent != null and parent.is_in_group("interactable_prop"):
		return parent
	return null


func _start_hit_stop() -> void:
	if _hit_stop_active or tuning.attack_hit_stop_sec <= 0.0:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(tuning.attack_hit_stop_sec, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


func _create_attack_fx_nodes() -> void:
	_windup_telegraph = Polygon2D.new()
	_windup_telegraph.name = "BiteWindupTelegraph"
	_windup_telegraph.polygon = PackedVector2Array([
		Vector2(22.0, -17.0),
		Vector2(68.0, 0.0),
		Vector2(22.0, 17.0),
	])
	_windup_telegraph.color = Color(1.0, 0.72, 0.28, tuning.attack_windup_telegraph_alpha)
	_windup_telegraph.visible = false
	_windup_telegraph.z_index = 4
	_visual.add_child(_windup_telegraph)


func _show_windup_telegraph() -> void:
	if _windup_telegraph == null:
		return
	_windup_telegraph.visible = true
	_windup_telegraph.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_windup_telegraph, "modulate:a", 1.0, frames_to_seconds(tuning.attack_startup_frames))


func _hide_windup_telegraph() -> void:
	if _windup_telegraph == null:
		return
	_windup_telegraph.visible = false


func _play_connect_feedback(include_camera_nudge: bool) -> void:
	_flash_snout()
	_spawn_bite_dust(global_position + _bite_direction * tuning.attack_hitbox_offset, _bite_direction, Color(1.0, 0.7, 0.34, 0.62), 5)
	if include_camera_nudge:
		_nudge_camera()


func _play_whiff_feedback() -> void:
	_play_sfx(&"play_bite_whiff")
	if tuning.attack_whiff_dust_enabled:
		_spawn_bite_dust(global_position + _bite_direction * tuning.attack_hitbox_offset, _bite_direction, Color(0.72, 0.62, 0.48, 0.36), 3)


func _flash_snout() -> void:
	if _snout == null:
		return
	if _snout_flash_tween != null and _snout_flash_tween.is_running():
		_snout_flash_tween.kill()
	_snout.modulate = Color(1.0, 0.82, 0.42, 1.0)
	_snout_flash_tween = create_tween()
	_snout_flash_tween.tween_property(_snout, "modulate", Color.WHITE, tuning.attack_connect_flash_sec)


func _spawn_bite_dust(origin: Vector2, direction: Vector2, color: Color, count: int) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var forward := direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	var side := forward.orthogonal()
	for i in range(count):
		var dust := ColorRect.new()
		dust.name = "BiteDust"
		dust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dust.size = Vector2(5.0, 3.0)
		dust.pivot_offset = dust.size * 0.5
		dust.color = color
		dust.rotation = forward.angle()
		parent.add_child(dust)
		dust.global_position = origin + side * randf_range(-8.0, 8.0)
		var drift := forward * randf_range(12.0, 24.0) + side * randf_range(-10.0, 10.0)
		var tween := dust.create_tween()
		tween.parallel().tween_property(dust, "global_position", dust.global_position + drift, 0.16)
		tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.16)
		tween.tween_callback(dust.queue_free)


func _nudge_camera() -> void:
	if _camera == null or tuning.attack_camera_nudge_px <= 0.0:
		return
	if _camera_nudge_tween != null and _camera_nudge_tween.is_running():
		_camera_nudge_tween.kill()
	_camera.offset = _camera_rest_offset - _bite_direction.normalized() * tuning.attack_camera_nudge_px
	_camera_nudge_tween = create_tween()
	_camera_nudge_tween.tween_property(_camera, "offset", _camera_rest_offset, tuning.attack_camera_nudge_sec)


func _begin_respawn() -> void:
	_is_respawning = true
	_enter_state(State.HITSTUN, 0)
	_body_shape.set_deferred("disabled", true)
	_disable_attack_hitbox()
	_tween_visual_scale(Vector2.ONE, 0.08)

	var fade_out := create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, tuning.respawn_fade_sec)
	await fade_out.finished

	global_position = _get_respawn_position()
	velocity = Vector2.ZERO
	_health.reset_full(true)

	_body_shape.set_deferred("disabled", false)
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, tuning.respawn_fade_sec)
	await fade_in.finished

	_is_respawning = false
	_enter_state(State.MOVE, 0)


func _get_respawn_position() -> Vector2:
	var arena := get_tree().get_first_node_in_group("topdown_arena")
	if arena != null and arena.has_method("get_spawn_position"):
		return arena.call("get_spawn_position")
	return global_position


func _update_invuln_visual() -> void:
	if _health == null:
		return
	if _health.is_invulnerable():
		var blink_on := (int(Time.get_ticks_msec() / 90) % 2) == 0
		_visual.modulate.a = 0.52 if blink_on else 0.88
	else:
		_visual.modulate.a = 1.0


func _flash_hit() -> void:
	_visual.modulate = Color(1.0, 0.52, 0.42, _visual.modulate.a)
	var tween := create_tween()
	tween.tween_property(_visual, "modulate", Color(1.0, 1.0, 1.0, _visual.modulate.a), 0.12)


func _tween_visual_scale(target_scale: Vector2, duration: float) -> void:
	if _attack_tween != null and _attack_tween.is_running():
		_attack_tween.kill()
	_attack_tween = create_tween()
	_attack_tween.tween_property(_visual, "scale", target_scale, maxf(duration, 0.01))


func _play_sfx(method_name: StringName) -> void:
	var sfx := GameSfxScript.instance()
	if sfx != null and sfx.has_method(method_name):
		sfx.call(method_name)


func frames_to_seconds(frame_count: int) -> float:
	return float(maxi(frame_count, 1)) / 60.0
