extends Node

const RIVAL_DOG_SCENE := preload("res://scenes/topdown/rival_dog.tscn")

@export var segment_path: NodePath = ^".."
@export var rivals_path: NodePath = ^"../Rivals"
@export var emerge_duration_min: float = 0.42
@export var emerge_duration_max: float = 0.78
@export var emerge_stagger_sec: float = 0.08

var _segment: Node
var _rivals: Node2D


func _ready() -> void:
	call_deferred("restart_wave")


func restart_wave() -> void:
	_bind()
	if _segment == null or _rivals == null:
		return
	_clear_rivals()

	var archetypes: Array = _segment.call("get_rival_archetypes")
	for i in range(archetypes.size()):
		var archetype := archetypes[i] as RivalArchetype
		if archetype == null:
			continue
		_spawn_emerging_rival(archetype, i)


func sync_rival_tuning() -> void:
	if _rivals == null:
		_bind()
	if _rivals == null:
		return
	for child in _rivals.get_children():
		if child.has_method("sync_tuning") and _segment != null and _segment.get("tuning") != null:
			child.call("sync_tuning", _segment.get("tuning"))


func _bind() -> void:
	_segment = get_node_or_null(segment_path)
	_rivals = get_node_or_null(rivals_path) as Node2D


func _spawn_emerging_rival(archetype: RivalArchetype, index: int) -> void:
	var spawn_position: Vector2 = _segment.call("get_rival_dark_spawn", archetype.id)
	var emerge_position: Vector2 = _segment.call("get_rival_emerge_position", archetype.id)

	var rival := RIVAL_DOG_SCENE.instantiate() as CharacterBody2D
	rival.name = "RivalDog_%s" % archetype.display_name.replace(" ", "")
	rival.position = _rivals.to_local(emerge_position)
	rival.set("tuning", _segment.get("tuning"))
	rival.set("archetype", archetype)
	_rivals.add_child(rival)

	rival.global_position = spawn_position
	rival.modulate.a = 0.42
	rival.set_physics_process(false)
	rival.set_process(false)

	var delay := float(index) * emerge_stagger_sec
	var duration := lerpf(emerge_duration_min, emerge_duration_max, float(index) / 3.0)
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(rival, "global_position", emerge_position, duration)
	tween.parallel().tween_property(rival, "modulate:a", 1.0, duration)
	tween.finished.connect(_on_emerge_finished.bind(rival))


func _on_emerge_finished(rival: CharacterBody2D) -> void:
	if not is_instance_valid(rival):
		return
	rival.set_physics_process(true)
	rival.set_process(true)


func _clear_rivals() -> void:
	for child in _rivals.get_children():
		child.queue_free()
