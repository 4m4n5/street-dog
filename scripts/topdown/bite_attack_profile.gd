extends Resource
class_name BiteAttackProfile

@export_group("Frames")
@export var startup_frames: int = 3
@export var active_frames: int = 3
@export var recovery_frames: int = 12
@export var recovery_move_unlock: int = 8

@export_group("Motion")
@export var startup_speed_mult: float = 0.35
@export var lunge_speed: float = 500.0

@export_group("Hitbox")
@export var hitbox_offset: float = 34.0
@export var hitbox_size: Vector2 = Vector2(48.0, 34.0)

@export_group("Impact")
@export var knockback_target: float = 150.0
@export var self_knockback: float = 24.0
@export var hit_stop_sec: float = 0.025

@export_group("Telegraph")
@export var windup_telegraph_alpha: float = 0.68
@export var telegraph_color: Color = Color(1.0, 0.32, 0.16, 0.74)
