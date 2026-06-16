extends TopdownProp


func _ready() -> void:
	prop_kind = &"laundry_line_poles"
	cover_tier = &"high"
	super._ready()


func on_bite_hit(biter: Node2D, direction: Vector2, damage: int) -> void:
	_play_sfx(&"play_parry")
	_flash_hit(Color(0.86, 0.82, 0.64, 1.0))
