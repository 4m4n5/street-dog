extends TopdownProp

@export var hp: int = 1


func _ready() -> void:
	prop_kind = &"cardboard_box"
	cover_tier = &"low"
	super._ready()


func on_bite_hit(biter: Node2D, direction: Vector2, damage: int) -> void:
	hp -= maxi(damage, 1)
	_play_sfx(&"play_prop_break")
	_flash_hit(Color(0.86, 0.62, 0.36, 1.0))
	if hp <= 0:
		queue_free()
