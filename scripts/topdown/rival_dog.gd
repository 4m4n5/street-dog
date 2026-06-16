extends CharacterBody2D

const GameSfxScript := preload("res://scripts/audio/game_sfx.gd")

enum State {
	IDLE,
	PATROL,
	CHASE,
	BITE_STARTUP,
	BITE_ACTIVE,
	BITE_RECOVERY,
	STAGGER,
	DEAD,
}

@export var tuning: TopdownTuning = TopdownTuning.new()
@export var archetype: RivalArchetype
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
@onready var _telegraph: Polygon2D = $Visual/Telegraph
@onready var _health_fill: ColorRect = $HealthBar/Fill

var _state := State.IDLE
var _state_frames_remaining := 0
var _hp := 2
var _home_position := Vector2.ZERO
var _facing_direction := Vector2.LEFT
var _bite_direction := Vector2.LEFT
var _target_hit_this_bite := false
var _patrol_phase := 0.0
var _flash_tween: Tween
var _hit_stop_active := false
var _noise_aggro_until_msec := 0
var _bite := BiteAttackProfile.new()
var _ai_role: StringName = &"patrol"
var _move_speed := 175.0
var _detection_range := 220.0
var _leash_radius := 0.0
var _patrol_radius := 72.0
var _display_name := "Rival"


func _ready() -> void:
	_ensure_tuning()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("rival_dog")
	add_to_group("hurtbox")
	_home_position = global_position
	_apply_archetype()
	_hp = max_hp
	_apply_visual_palette()
	_configure_attack_hitbox()
	_update_health_bar()
	_telegraph.visible = false
	_attack_hitbox.body_entered.connect(_on_attack_body_entered)
	_enter_state(State.PATROL, 0)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	var player := get_tree().get_first_node_in_group("player") as Node2D
	match _state:
		State.IDLE:
			_process_idle(delta, player)
		State.PATROL:
			_process_patrol(delta, player)
		State.CHASE:
			_process_chase(delta, player)
		State.BITE_STARTUP:
			_process_bite_startup(delta)
		State.BITE_ACTIVE:
			_process_bite_active()
		State.BITE_RECOVERY:
			_process_bite_recovery(delta)
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
		_apply_stagger(_get_stagger_frames(hit_stop), knockback)
		_flash_hit()

	return true


func apply_stagger(frames: int = 8, knockback: Vector2 = Vector2.ZERO) -> bool:
	if _state == State.DEAD:
		return false
	_apply_stagger(frames, knockback)
	_flash_hit(Color(0.72, 0.82, 1.0, 1.0))
	return true


func is_dead() -> bool:
	return _state == State.DEAD


func alert_from_noise(source_position: Vector2, duration_sec: float = 2.0) -> void:
	if _state == State.DEAD:
		return
	_noise_aggro_until_msec = maxi(_noise_aggro_until_msec, Time.get_ticks_msec() + int(duration_sec * 1000.0))
	if _state == State.IDLE or _state == State.PATROL:
		_enter_state(State.CHASE, 0)


func sync_tuning(next_tuning: TopdownTuning) -> void:
	if next_tuning != null:
		tuning = next_tuning


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = TopdownTuning.new()


func _apply_archetype() -> void:
	_move_speed = tuning.rival_move_speed
	_detection_range = tuning.rival_detection_range
	_patrol_radius = tuning.rival_patrol_radius
	_leash_radius = 0.0
	_ai_role = &"patrol"
	_display_name = name
	_bite = _legacy_bite_profile()

	if archetype == null:
		return

	_display_name = archetype.display_name
	_ai_role = archetype.ai_role
	max_hp = archetype.max_hp
	_move_speed = archetype.move_speed
	_detection_range = archetype.detection_range
	_leash_radius = archetype.leash_radius
	_patrol_radius = archetype.patrol_radius
	body_color = archetype.body_color
	head_color = archetype.head_color
	shoulder_scale = archetype.shoulder_scale
	if archetype.bite != null:
		_bite = archetype.bite


func _legacy_bite_profile() -> BiteAttackProfile:
	var profile := BiteAttackProfile.new()
	profile.startup_frames = tuning.rival_windup_frames
	profile.active_frames = tuning.rival_attack_frames
	profile.recovery_frames = tuning.rival_recover_frames
	profile.recovery_move_unlock = tuning.rival_recover_frames
	profile.startup_speed_mult = 0.22
	profile.lunge_speed = tuning.rival_attack_lunge_speed
	profile.hitbox_offset = tuning.rival_attack_hitbox_offset
	profile.hitbox_size = tuning.rival_attack_hitbox_size
	profile.knockback_target = tuning.rival_bite_knockback
	profile.self_knockback = 18.0
	profile.hit_stop_sec = 0.02
	profile.windup_telegraph_alpha = 0.72
	profile.telegraph_color = Color(1.0, 0.36, 0.18, 0.72)
	return profile


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
	velocity = velocity.move_toward(Vector2.ZERO, tuning.rival_recover_friction * delta)
	if _can_engage_player(player):
		_enter_state(State.CHASE, 0)
	else:
		_enter_state(State.PATROL, 0)


func _process_patrol(delta: float, player: Node2D) -> void:
	if _can_engage_player(player):
		_enter_state(State.CHASE, 0)
		return

	_patrol_phase += delta * _get_patrol_rate()
	var patrol_target := _get_patrol_target()
	var direction := global_position.direction_to(patrol_target) if global_position.distance_to(patrol_target) > 8.0 else Vector2.ZERO
	_apply_direction(direction, _move_speed * tuning.rival_patrol_speed_mult, delta)


func _process_chase(delta: float, player: Node2D) -> void:
	if not _can_engage_player(player):
		_return_to_patrol(delta)
		return

	var distance := global_position.distance_to(player.global_position)
	if distance <= _get_attack_range():
		_start_bite(player.global_position)
		return

	var chase_direction := global_position.direction_to(player.global_position)
	if _ai_role == &"skirmish":
		var side_bias := chase_direction.orthogonal() * sin(_patrol_phase + Time.get_ticks_msec() * 0.006) * 0.38
		chase_direction = (chase_direction + side_bias).normalized()
	chase_direction = (chase_direction + _get_separation()).normalized()
	_apply_direction(chase_direction, _move_speed, delta)


func _process_bite_startup(delta: float) -> void:
	_face_direction(_bite_direction, delta)
	velocity = velocity.move_toward(_bite_direction * (_move_speed * _bite.startup_speed_mult), tuning.move_accel * delta)
	_show_telegraph()
	_tick_state_frame()
	if _state_frames_remaining <= 0:
		_enter_bite_active()


func _process_bite_active() -> void:
	velocity = _bite_direction * _bite.lunge_speed
	_update_attack_hitbox_transform()
	_tick_state_frame()
	if _state_frames_remaining <= 0:
		_enter_bite_recovery()


func _process_bite_recovery(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, tuning.rival_recover_friction * delta)
	_tick_state_frame()
	if _state_frames_remaining <= 0:
		_enter_state(State.CHASE, 0)


func _process_stagger(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, tuning.rival_recover_friction * delta)
	_tick_state_frame()
	if _state_frames_remaining <= 0:
		_enter_state(State.CHASE, 0)


func _get_patrol_rate() -> float:
	match _ai_role:
		&"leash":
			return 0.45
		&"skirmish":
			return 1.25
		&"bully":
			return 0.62
		_:
			return 0.9


func _get_patrol_target() -> Vector2:
	if _ai_role == &"leash":
		return _home_position
	var radius := _patrol_radius
	var x_scale := 1.35 if _ai_role == &"skirmish" else 1.0
	var y_scale := 0.65 if _ai_role == &"skirmish" else 0.7
	return _home_position + Vector2(cos(_patrol_phase) * radius * x_scale, sin(_patrol_phase * 0.7) * radius * y_scale)


func _return_to_patrol(delta: float) -> void:
	var distance_home := global_position.distance_to(_home_position)
	if distance_home > 10.0:
		_apply_direction(global_position.direction_to(_home_position), _move_speed * 0.72, delta)
	else:
		_enter_state(State.PATROL, 0)


func _start_bite(target_position: Vector2) -> void:
	_bite_direction = global_position.direction_to(target_position)
	if _bite_direction == Vector2.ZERO:
		_bite_direction = _facing_direction
	_bite_direction = _bite_direction.normalized()
	_facing_direction = _bite_direction
	_face_direction(_bite_direction, 1.0)
	_update_attack_hitbox_transform()
	_show_telegraph(true)
	_tween_visual_scale(Vector2(0.92, 1.10), frames_to_seconds(_bite.startup_frames))
	_enter_state(State.BITE_STARTUP, _bite.startup_frames)


func _enter_bite_active() -> void:
	_target_hit_this_bite = false
	_telegraph.visible = false
	_enable_attack_hitbox(true)
	_tween_visual_scale(Vector2(1.18, 0.84), frames_to_seconds(_bite.active_frames))
	_enter_state(State.BITE_ACTIVE, _bite.active_frames)


func _enter_bite_recovery() -> void:
	_disable_attack_hitbox()
	_tween_visual_scale(Vector2.ONE, frames_to_seconds(_bite.recovery_frames))
	_enter_state(State.BITE_RECOVERY, _bite.recovery_frames)


func _enter_state(next_state: State, frames: int) -> void:
	_state = next_state
	_state_frames_remaining = maxi(frames, 0)
	if _state != State.BITE_STARTUP:
		_telegraph.visible = false
	if _state != State.BITE_ACTIVE:
		_disable_attack_hitbox()
	if _state == State.PATROL or _state == State.CHASE:
		_tween_visual_scale(Vector2.ONE, 0.08)


func _apply_stagger(frames: int, knockback: Vector2) -> void:
	_disable_attack_hitbox()
	_telegraph.visible = false
	velocity = knockback
	_enter_state(State.STAGGER, maxi(frames, 1))


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


func _can_engage_player(player: Node2D) -> bool:
	if player == null:
		return false
	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player > _detection_range and not _has_noise_aggro():
		return false
	if _leash_radius > 0.0 and _home_position.distance_to(player.global_position) > _leash_radius:
		return false
	return true


func _has_noise_aggro() -> bool:
	return Time.get_ticks_msec() <= _noise_aggro_until_msec


func _get_attack_range() -> float:
	return maxf(tuning.rival_attack_range, _bite.hitbox_offset + 12.0)


func _get_separation() -> Vector2:
	var steering := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("rival_dog"):
		if other == self or not (other is Node2D):
			continue
		if other.has_method("is_dead") and other.call("is_dead"):
			continue
		var other_node := other as Node2D
		var offset := global_position - other_node.global_position
		var distance := offset.length()
		if distance > 0.0 and distance < tuning.rival_separation_radius:
			steering += offset.normalized() * ((tuning.rival_separation_radius - distance) / tuning.rival_separation_radius)
	return steering * tuning.rival_separation_force / maxf(_move_speed, 1.0)


func _configure_attack_hitbox() -> void:
	_telegraph.color = _bite.telegraph_color
	var shape := _attack_shape.shape as RectangleShape2D
	if shape != null:
		shape.size = _bite.hitbox_size
	_update_attack_hitbox_transform()
	_disable_attack_hitbox()


func _update_attack_hitbox_transform() -> void:
	_attack_hitbox.position = _bite_direction * _bite.hitbox_offset
	_attack_hitbox.rotation = _bite_direction.angle()
	var shape := _attack_shape.shape as RectangleShape2D
	if shape != null:
		shape.size = _bite.hitbox_size


func _enable_attack_hitbox(enabled: bool) -> void:
	_attack_hitbox.set_deferred("monitoring", enabled)
	_attack_shape.set_deferred("disabled", not enabled)


func _disable_attack_hitbox() -> void:
	_enable_attack_hitbox(false)


func _show_telegraph(reset_alpha: bool = false) -> void:
	_telegraph.color = _bite.telegraph_color
	_telegraph.visible = true
	if reset_alpha:
		_telegraph.modulate.a = 0.0
	var pulse := 0.82 + sin(Time.get_ticks_msec() * 0.018) * 0.18
	_telegraph.modulate.a = minf(_bite.windup_telegraph_alpha * pulse, 1.0)


func _on_attack_body_entered(body: Node) -> void:
	if _state != State.BITE_ACTIVE or _target_hit_this_bite or not body.is_in_group("player"):
		return
	if not body.has_method("receive_enemy_hit"):
		return
	_target_hit_this_bite = true
	var knockback := _bite_direction * _bite.knockback_target
	body.call("receive_enemy_hit", tuning.rival_contact_damage, knockback, self)
	velocity -= _bite_direction * _bite.self_knockback
	_start_hit_stop()


func _start_hit_stop() -> void:
	if _hit_stop_active or _bite.hit_stop_sec <= 0.0:
		return
	_hit_stop_active = true
	Engine.time_scale = 0.0
	await get_tree().create_timer(_bite.hit_stop_sec, true, false, true).timeout
	Engine.time_scale = 1.0
	_hit_stop_active = false


func _get_stagger_frames(hit_stop: float) -> int:
	var hit_stop_frames := int(ceilf(maxf(hit_stop, 0.0) * 60.0))
	return maxi(tuning.rival_stagger_frames, hit_stop_frames)


func _update_health_bar() -> void:
	if _health_fill == null:
		return
	var ratio := float(_hp) / float(maxi(max_hp, 1))
	_health_fill.scale.x = clampf(ratio, 0.0, 1.0)


func _flash_hit(color: Color = Color(1.0, 0.48, 0.38, 1.0)) -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()
	_visual.modulate = color
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
