extends CharacterBody2D

const GameSfxScript = preload("res://scripts/audio/game_sfx.gd")

## Mumbai street threat — patrols footpath, telegraphed swipe, takes bites.

enum State { PATROL, WINDUP, ATTACK, RECOVER, STAGGER, DEAD }

@export var patrol_half_width: float = 140.0
@export var move_speed: float = 70.0
@export var max_health: int = 4
@export var contact_damage: int = 1
@export var detection_range: float = 210.0
@export var attack_range: float = 58.0
@export var windup_frames: int = 18
@export var attack_frames: int = 4
@export var recover_frames: int = 20
@export var stagger_frames: int = 24

@onready var _visual: Node2D = $Visual
@onready var _telegraph: ColorRect = $Visual/Telegraph
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _attack_hitbox: Area2D = $AttackHitbox

var _state := State.PATROL
var _state_frames_left := 0
var _health := 4
var _facing := 1
var _patrol_origin := Vector2.ZERO
var _knockback_velocity := Vector2.ZERO
var _attack_hit_player := false
var _player: CharacterBody2D
var _sfx: GameSfxScript


func _ready() -> void:
	_sfx = GameSfxScript.instance()
	add_to_group("enemy")
	_health = max_health
	_patrol_origin = global_position
	_telegraph.visible = false
	_attack_hitbox.monitoring = false
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not _attack_hitbox.body_entered.is_connected(_on_attack_hitbox_body_entered):
		_attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	call_deferred("_capture_patrol_origin")


func _capture_patrol_origin() -> void:
	_patrol_origin = global_position


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	if _knockback_velocity.length_squared() > 1.0:
		global_position += _knockback_velocity * delta
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)

	_apply_gravity(delta)
	_apply_state(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		return
	velocity += get_gravity() * delta


func _apply_state(delta: float) -> void:
	match _state:
		State.PATROL:
			_patrol(delta)
		State.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			_tick_state(State.ATTACK, attack_frames)
		State.ATTACK:
			velocity.x = 0.0
			_tick_state(State.RECOVER, recover_frames)
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			_tick_state(State.PATROL, 0)
		State.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			_tick_state(State.PATROL, 0)


func _patrol(_delta: float) -> void:
	if _player != null and is_instance_valid(_player):
		var to_player := _player.global_position - global_position
		if absf(to_player.x) <= detection_range and absf(to_player.y) < 48.0:
			_face_towards(int(signf(to_player.x)))
			if absf(to_player.x) <= attack_range:
				_enter_windup()
				return

	var left_bound := _patrol_origin.x - patrol_half_width
	var right_bound := _patrol_origin.x + patrol_half_width
	if global_position.x <= left_bound:
		_facing = 1
	elif global_position.x >= right_bound:
		_facing = -1
	_face_towards(_facing)
	velocity.x = float(_facing) * move_speed


func _enter_windup() -> void:
	_state = State.WINDUP
	_state_frames_left = windup_frames
	_telegraph.visible = true
	_telegraph.modulate = Color(1.0, 0.92, 0.55, 0.85)


func _enter_attack() -> void:
	_state = State.ATTACK
	_state_frames_left = attack_frames
	_telegraph.visible = false
	_attack_hit_player = false
	_set_attack_hitbox_monitoring(true)
	_visual.modulate = Color(1.2, 0.85, 0.75, 1.0)


func _enter_recover() -> void:
	_state = State.RECOVER
	_state_frames_left = recover_frames
	_set_attack_hitbox_monitoring(false)
	_visual.modulate = Color.WHITE


func _enter_stagger() -> void:
	_state = State.STAGGER
	_state_frames_left = stagger_frames
	_set_attack_hitbox_monitoring(false)
	_telegraph.visible = false
	_visual.modulate = Color(0.75, 0.9, 1.1, 1.0)


func _tick_state(next_state: State, next_frames: int) -> void:
	_state_frames_left -= 1
	if _state_frames_left > 0:
		return

	match _state:
		State.WINDUP:
			_enter_attack()
		State.ATTACK:
			_enter_recover()
		State.RECOVER, State.STAGGER:
			_state = next_state
			_state_frames_left = next_frames
			_visual.modulate = Color.WHITE


func take_hit(knockback: Vector2, _hit_stop: bool) -> void:
	if _state == State.DEAD:
		return

	_health -= 1
	_knockback_velocity = knockback
	_flash_hit()
	_sfx.play_hit()

	if _health <= 0:
		_die()
		return

	_enter_stagger()


func on_parried() -> void:
	if _state == State.DEAD:
		return
	_health = maxi(_health - 1, 0)
	_knockback_velocity = Vector2(float(-_facing) * 160.0, -40.0)
	_enter_stagger()
	if _health <= 0:
		_die()


func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if _state != State.ATTACK or _attack_hit_player:
		return
	if not body.is_in_group("player"):
		return
	_attack_hit_player = true
	_set_attack_hitbox_monitoring(false)
	if body.has_method("receive_enemy_hit"):
		body.call("receive_enemy_hit", contact_damage, Vector2(float(_facing) * 180.0, -60.0), self)


func _set_attack_hitbox_monitoring(enabled: bool) -> void:
	_attack_hitbox.set_deferred("monitoring", enabled)


func _face_towards(direction: int) -> void:
	if direction == 0:
		return
	_facing = direction
	_visual.scale.x = absf(_visual.scale.x) * float(_facing)
	_attack_hitbox.position.x = 34.0 * float(_facing)


func _flash_hit() -> void:
	var tween := create_tween()
	_visual.modulate = Color(1.5, 1.1, 1.0, 1.0)
	tween.tween_property(_visual, "modulate", Color.WHITE, 0.1)


func _die() -> void:
	_state = State.DEAD
	_set_attack_hitbox_monitoring(false)
	_telegraph.visible = false
	collision_layer = 0
	$CollisionShape2D.set_deferred("disabled", true)
	_hurtbox.set_deferred("monitoring", false)
	_sfx.play_enemy_defeat()
	var tween := create_tween()
	tween.tween_property(_visual, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(_visual, "scale", Vector2(0.4, 1.2), 0.2)
	tween.tween_callback(queue_free)
