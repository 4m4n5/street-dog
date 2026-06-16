extends Resource
class_name RivalArchetype

@export_group("Identity")
@export var id: StringName = &"stray"
@export var display_name: String = "Stray"
@export var ai_role: StringName = &"patrol"

@export_group("Vitals")
@export var max_hp: int = 2
@export var move_speed: float = 175.0
@export var detection_range: float = 220.0
@export var leash_radius: float = 0.0
@export var patrol_radius: float = 72.0

@export_group("Readability")
@export var body_color: Color = Color(0.18, 0.18, 0.17, 1.0)
@export var head_color: Color = Color(0.10, 0.10, 0.095, 1.0)
@export var shoulder_scale: float = 1.0

@export_group("Bite")
@export var bite: BiteAttackProfile = BiteAttackProfile.new()
