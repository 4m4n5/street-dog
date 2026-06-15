extends Resource
class_name TopdownTuning

## Shared v0 defaults for the top-down Mumbai gully prototype.
## Scene scripts expose this Resource in the Inspector so feel can be tuned live.

@export_group("Player Movement")
@export var move_speed: float = 290.0
@export var move_accel: float = 2000.0
@export var move_friction: float = 2400.0
@export var input_deadzone: float = 0.2
@export var rotation_lerp_speed: float = 18.0
@export var allow_diagonal: bool = true

@export_group("Player Bite")
@export var attack_startup_frames: int = 2
@export var attack_active_frames: int = 3
@export var attack_recovery_frames: int = 10
@export var attack_recovery_move_unlock: int = 6
@export var attack_startup_speed_mult: float = 0.35
@export var attack_lunge_speed: float = 540.0
@export var attack_hitbox_offset: float = 28.0
@export var attack_hitbox_size: Vector2 = Vector2(44.0, 36.0)
@export var attack_knockback_target: float = 160.0
@export var attack_self_knockback: float = 48.0
@export var attack_hit_stop_sec: float = 0.055

@export_group("Player Attack Buffer")
@export var attack_buffer_frames: int = 8
@export var attack_coyote_frames: int = 6
@export var attack_recovery_buffer_frames: int = 4

@export_group("Player Attack Juice")
@export var attack_windup_telegraph_alpha: float = 0.55
@export var attack_connect_flash_sec: float = 0.06
@export var attack_whiff_dust_enabled: bool = true
@export var attack_camera_nudge_px: float = 3.0
@export var attack_camera_nudge_sec: float = 0.05

@export_group("Player Health")
@export var player_max_hp: int = 3
@export var player_invuln_sec: float = 0.85
@export var player_hitstun_frames: int = 12
@export var respawn_full_hp: bool = true
@export var respawn_fade_sec: float = 0.35

@export_group("Rival Dog")
@export var rival_move_speed: float = 175.0
@export var rival_detection_range: float = 220.0
@export var rival_attack_range: float = 42.0
@export var rival_windup_frames: int = 20
@export var rival_attack_frames: int = 4
@export var rival_recover_frames: int = 18
@export var rival_attack_lunge_speed: float = 260.0
@export var rival_attack_hitbox_offset: float = 34.0
@export var rival_attack_hitbox_size: Vector2 = Vector2(48.0, 34.0)
@export var rival_max_hp_grunt: int = 2
@export var rival_max_hp_bully: int = 3
@export var rival_contact_damage: int = 1
@export var rival_bite_knockback: float = 160.0
@export var rival_patrol_radius: float = 72.0
@export var rival_patrol_speed_mult: float = 0.55
@export var rival_stagger_frames: int = 4
@export var rival_recover_friction: float = 1800.0
@export var rival_separation_radius: float = 48.0
@export var rival_separation_force: float = 80.0

@export_group("Arena")
@export var arena_width: float = 1280.0
@export var arena_height: float = 720.0
@export var footpath_color: Color = Color(0.155, 0.15, 0.135, 1.0)
@export var wall_inset: float = 32.0
@export var spawn_player: Vector2 = Vector2(150.0, 536.0)
@export var spawn_rival_a: Vector2 = Vector2(600.0, 472.0)
@export var spawn_rival_b: Vector2 = Vector2(1110.0, 296.0)


@export_group("Arena Palette")
@export var gully_wall_color: Color = Color(0.075, 0.085, 0.09, 1.0)
@export var chawl_wall_color: Color = Color(0.13, 0.125, 0.115, 1.0)
@export var corrugated_lip_color: Color = Color(0.09, 0.105, 0.115, 1.0)
@export var wet_sheen_color: Color = Color(0.32, 0.42, 0.52, 0.24)
@export var chai_stall_color: Color = Color(0.18, 0.105, 0.045, 1.0)
@export var chai_stall_amber: Color = Color(0.95, 0.62, 0.28, 0.78)
@export var puddle_color: Color = Color(0.09, 0.16, 0.22, 0.62)
@export var best_green_color: Color = Color(0.055, 0.21, 0.18, 1.0)
