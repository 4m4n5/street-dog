extends TopdownProp


func _ready() -> void:
	prop_kind = &"scooter"
	cover_tier = &"high"
	super._ready()


func on_bite_hit(biter: Node2D, direction: Vector2, damage: int) -> void:
	_play_sfx(&"play_parry")
	_flash_hit(Color(0.72, 0.76, 0.70, 1.0))
