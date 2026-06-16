class_name TopdownProp
extends StaticBody2D

const GameSfxScript := preload("res://scripts/audio/game_sfx.gd")

const WORLD_LAYER := 1
const INTERACTABLE_LAYER := 8

@export var prop_kind: StringName
@export var cover_tier: StringName = &"high"
@export var alert_radius: float = 0.0


func _ready() -> void:
	add_to_group("interactable_prop")
	collision_layer |= WORLD_LAYER | INTERACTABLE_LAYER
	collision_mask = 0


func on_bite_hit(biter: Node2D, direction: Vector2, damage: int) -> void:
	pass


func _safe_direction(direction: Vector2) -> Vector2:
	if direction.length_squared() <= 0.01:
		return Vector2.RIGHT
	return direction.normalized()


func _play_sfx(method_name: StringName) -> void:
	var sfx := GameSfxScript.instance()
	if sfx != null and sfx.has_method(method_name):
		sfx.call(method_name)


func _alert_rivals(source_position: Vector2, duration_sec: float, radius: float = -1.0) -> void:
	var search_radius := alert_radius if radius < 0.0 else radius
	if search_radius <= 0.0:
		return
	for rival in get_tree().get_nodes_in_group("rival_dog"):
		if not (rival is Node2D):
			continue
		var rival_node := rival as Node2D
		if source_position.distance_to(rival_node.global_position) > search_radius:
			continue
		if rival_node.has_method("alert_from_noise"):
			rival_node.call("alert_from_noise", source_position, duration_sec)


func _flash_hit(color: Color = Color(1.0, 0.82, 0.42, 1.0)) -> void:
	modulate = color
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.12)
