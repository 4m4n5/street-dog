extends Node2D

## Keeps one shared TopdownTuning reference on all top-down gameplay nodes.

const DEFAULT_TUNING := preload("res://resources/topdown/default_tuning.tres")

@export var tuning: TopdownTuning = DEFAULT_TUNING


func _ready() -> void:
	if tuning == null:
		tuning = DEFAULT_TUNING.duplicate(true)
	_apply_shared_tuning()


func _apply_shared_tuning() -> void:
	var arena := $ArenaMumbaiGully
	if arena != null and arena.get("tuning") != null:
		arena.tuning = tuning

	var player := $PlayerDogTopdown as CharacterBody2D
	if player != null and player.get("tuning") != null:
		player.tuning = tuning
		var health := player.get_node_or_null("PlayerHealthTopdown")
		if health != null and health.get("tuning") != null:
			health.tuning = tuning

	var hud := $PlayerHudTopdown
	if hud != null and hud.get("tuning") != null:
		hud.tuning = tuning

	if arena != null and arena.has_method("sync_rival_tuning"):
		arena.call("sync_rival_tuning")
