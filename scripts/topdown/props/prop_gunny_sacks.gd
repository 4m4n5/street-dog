extends TopdownProp

@export var debris_lifetime: float = 8.0

var _toppled := false


func _ready() -> void:
	prop_kind = &"gunny_sacks"
	cover_tier = &"low"
	super._ready()


func on_bite_hit(biter: Node2D, direction: Vector2, damage: int) -> void:
	if _toppled:
		return
	_toppled = true
	_play_sfx(&"play_prop_break")
	_spawn_debris(_safe_direction(direction))
	queue_free()


func _spawn_debris(direction: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var offsets := [
		Vector2(-22.0, -8.0),
		Vector2(14.0, 10.0),
		direction * 34.0,
	]
	for i in range(offsets.size()):
		var debris := TopdownProp.new()
		debris.name = "GunnySackDebris_%02d" % i
		debris.prop_kind = &"gunny_sack_debris"
		debris.cover_tier = &"low"
		debris.position = position + offsets[i]
		debris.rotation = direction.angle() + float(i - 1) * 0.35

		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(28.0, 18.0)
		shape_node.shape = shape
		debris.add_child(shape_node)

		var visual := ColorRect.new()
		visual.name = "Visual"
		visual.offset_left = -14.0
		visual.offset_top = -9.0
		visual.offset_right = 14.0
		visual.offset_bottom = 9.0
		visual.color = Color(0.44, 0.36, 0.22, 1.0)
		debris.add_child(visual)

		parent.add_child(debris)
		_despawn_after(debris, debris_lifetime)


func _despawn_after(node: Node, lifetime: float) -> void:
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(node):
		node.queue_free()
