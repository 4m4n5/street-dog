extends Node

const GameSfxScript := preload("res://scripts/audio/game_sfx.gd")
const DEFAULT_CLEAR_UI := preload("res://scenes/topdown/ui/encounter_clear_topdown.tscn")

@export var arena_path: NodePath = ^"../StreetSegmentGully01"
@export var clear_ui_scene: PackedScene = DEFAULT_CLEAR_UI
@export var clear_label_sec: float = 1.5
@export var respawn_delay_sec: float = 2.0

var _arena: Node
var _clear_ui: CanvasLayer
var _clear_in_progress := false
var _has_seen_rivals := false


func _ready() -> void:
	call_deferred("_bind")


func _process(_delta: float) -> void:
	if _arena == null or _clear_in_progress:
		return

	var living_count := _living_rival_count()
	if living_count > 0:
		_has_seen_rivals = true
		return
	if _has_seen_rivals:
		_run_clear_sequence()


func _bind() -> void:
	_arena = get_node_or_null(arena_path)
	if _arena == null:
		_arena = get_tree().get_first_node_in_group("topdown_arena")
	_ensure_clear_ui()


func _living_rival_count() -> int:
	var count := 0
	for rival in get_tree().get_nodes_in_group("rival_dog"):
		if rival.has_method("is_dead") and rival.call("is_dead"):
			continue
		count += 1
	return count


func _run_clear_sequence() -> void:
	_clear_in_progress = true
	_has_seen_rivals = false
	_show_clear_ui(true)
	_play_sfx(&"play_gully_clear")

	await get_tree().create_timer(clear_label_sec).timeout
	_show_clear_ui(false)

	var remaining_delay := maxf(respawn_delay_sec - clear_label_sec, 0.0)
	if remaining_delay > 0.0:
		await get_tree().create_timer(remaining_delay).timeout

	if _arena != null and _arena.has_method("respawn_rivals"):
		_arena.call("respawn_rivals")
	_clear_in_progress = false


func _ensure_clear_ui() -> void:
	if _clear_ui != null:
		return
	if clear_ui_scene == null:
		clear_ui_scene = DEFAULT_CLEAR_UI
	_clear_ui = clear_ui_scene.instantiate() as CanvasLayer
	add_child(_clear_ui)
	_show_clear_ui(false)


func _show_clear_ui(is_visible: bool) -> void:
	if _clear_ui == null:
		return
	_clear_ui.visible = is_visible
	var root := _clear_ui.get_node_or_null("Root") as CanvasItem
	if root != null:
		root.modulate.a = 1.0 if is_visible else 0.0


func _play_sfx(method_name: StringName) -> void:
	var sfx := GameSfxScript.instance()
	if sfx != null and sfx.has_method(method_name):
		sfx.call(method_name)
