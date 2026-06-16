extends TopdownProp


func _ready() -> void:
	prop_kind = &"chai_counter"
	cover_tier = &"high"
	alert_radius = 120.0
	super._ready()


func on_bite_hit(biter: Node2D, direction: Vector2, damage: int) -> void:
	_play_sfx(&"play_parry")
	_flash_hit(Color(1.0, 0.68, 0.32, 1.0))
	_alert_rivals(global_position, 2.0, alert_radius)
