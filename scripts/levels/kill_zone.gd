extends Area2D

@export var spawn_path: NodePath


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var spawn := get_node_or_null(spawn_path) as Node2D
	if spawn:
		body.global_position = spawn.global_position
	if body is CharacterBody2D:
		body.velocity = Vector2.ZERO
		_flash_respawn(body)


func _flash_respawn(player: CharacterBody2D) -> void:
	var visual := player.get_node_or_null("Visual") as CanvasItem
	if visual == null:
		return
	visual.modulate = Color(1.4, 1.2, 0.9, 0.35)
	var tween := player.create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.35)
