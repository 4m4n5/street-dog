extends Node2D

const RIVAL_DOG_SCENE := preload("res://scenes/topdown/rival_dog.tscn")
const PROP_CHAI_COUNTER_SCENE := preload("res://scenes/topdown/props/chai_stall_counter.tscn")
const PROP_PLASTIC_CHAIR_SCENE := preload("res://scenes/topdown/props/plastic_chair.tscn")
const PROP_GUNNY_SACKS_SCENE := preload("res://scenes/topdown/props/gunny_sacks.tscn")
const PROP_SCOOTER_SCENE := preload("res://scenes/topdown/props/parked_scooter.tscn")
const PROP_CARDBOARD_BOX_SCENE := preload("res://scenes/topdown/props/cardboard_box.tscn")
const PROP_BEST_BENCH_SCENE := preload("res://scenes/topdown/props/best_bench.tscn")
const PROP_LAUNDRY_LINE_SCENE := preload("res://scenes/topdown/props/laundry_line_poles.tscn")
const ARCHETYPE_STRAY := preload("res://resources/topdown/archetypes/stray.tres")
const ARCHETYPE_SENTRY := preload("res://resources/topdown/archetypes/sentry.tres")
const ARCHETYPE_RACER := preload("res://resources/topdown/archetypes/racer.tres")
const ARCHETYPE_BULLY := preload("res://resources/topdown/archetypes/bully.tres")

@export var tuning: TopdownTuning = TopdownTuning.new()
@export var rival_archetypes: Array[RivalArchetype] = []

@onready var _surface: Node2D = $Surface
@onready var _walls: Node2D = $Walls
@onready var _dressing: Node2D = $Dressing
@onready var _props: Node2D = $Props
@onready var _spawns: Node2D = $Spawns
@onready var _rivals: Node2D = $Rivals


func _ready() -> void:
	_ensure_tuning()
	add_to_group("topdown_arena")
	_build_room()
	_build_props()
	_position_markers()
	_spawn_rivals()
	call_deferred("_place_player")


func get_spawn_position() -> Vector2:
	return _get_marker_position("Spawn", tuning.spawn_player)


func get_rival_spawn_a() -> Vector2:
	return _get_marker_position("RivalSpawn_A", tuning.spawn_rival_a)


func get_rival_spawn_b() -> Vector2:
	return _get_marker_position("RivalSpawn_B", tuning.spawn_rival_b)


func get_rival_spawn(archetype_id: StringName) -> Vector2:
	return _get_marker_position(_marker_name_for_archetype(archetype_id), _fallback_spawn_for_archetype(archetype_id))


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = TopdownTuning.new()


func _build_room() -> void:
	_clear_children(_surface)
	_clear_children(_walls)
	_clear_children(_dressing)

	var size := Vector2(tuning.arena_width, tuning.arena_height)
	var top_bottom_depth := 96.0
	var left_right_depth := tuning.wall_inset
	_add_rect(_surface, "RainDarkAsphalt", Vector2.ZERO, size, Color("#090B0D"), -20)
	_add_floor_zone("SpawnFootholdWetPavers", Vector2(32.0, 112.0), Vector2(254.0, 512.0), Color("#272622"))
	_add_floor_zone("MainWetLane", Vector2(314.0, 112.0), Vector2(638.0, 226.0), Color("#2E2C28"))
	_add_floor_zone("ForkTJunction", Vector2(532.0, 250.0), Vector2(228.0, 194.0), Color("#302E29"))
	_add_floor_zone("CourtyardWell", Vector2(318.0, 384.0), Vector2(522.0, 240.0), Color("#272622"))
	_add_floor_zone("BESTAlcove", Vector2(980.0, 112.0), Vector2(268.0, 388.0), Color(0.13, 0.16, 0.145, 1.0))
	_add_floor_zone("SideLoopLane", Vector2(812.0, 506.0), Vector2(436.0, 118.0), Color("#252827"))

	_add_boundary("BoundaryTop_ChawlWall", Vector2.ZERO, Vector2(tuning.arena_width, top_bottom_depth), tuning.gully_wall_color)
	_add_boundary("BoundaryBottom_CorrugatedLip", Vector2(0.0, tuning.arena_height - top_bottom_depth), Vector2(tuning.arena_width, top_bottom_depth), tuning.corrugated_lip_color)
	_add_boundary("BoundaryLeft_NarrowGully", Vector2.ZERO, Vector2(tuning.wall_inset, tuning.arena_height), tuning.gully_wall_color)
	_add_boundary("BoundaryRight_NarrowGully", Vector2(tuning.arena_width - left_right_depth, 0.0), Vector2(left_right_depth, tuning.arena_height), tuning.gully_wall_color)

	_add_internal_wall("SpawnPartition_North", Vector2(286.0, 96.0), Vector2(28.0, 286.0))
	_add_internal_wall("SpawnPartition_South", Vector2(286.0, 444.0), Vector2(28.0, 180.0))
	_add_internal_wall("ForkDivider_Upper", Vector2(532.0, 338.0), Vector2(228.0, 28.0))
	_add_internal_wall("ForkDivider_Lower", Vector2(760.0, 366.0), Vector2(28.0, 146.0))
	_add_internal_wall("BusPartition_North", Vector2(952.0, 96.0), Vector2(28.0, 188.0))
	_add_internal_wall("BusPartition_South", Vector2(952.0, 500.0), Vector2(28.0, 124.0))
	_add_internal_wall("LoopIsland_ScooterWall", Vector2(610.0, 488.0), Vector2(156.0, 28.0))

	_add_chawl_wall()
	_add_puddles()
	_add_best_stop_stripe()
	_add_corrugated_lip()
	_add_light_slices()


func _build_props() -> void:
	_clear_children(_props)
	_spawn_prop(PROP_CHAI_COUNTER_SCENE, "ChaiStallCounter", Vector2(154.0, 482.0))
	_spawn_prop(PROP_PLASTIC_CHAIR_SCENE, "PlasticChair_MainLane", Vector2(438.0, 278.0), -0.12)
	_spawn_prop(PROP_GUNNY_SACKS_SCENE, "GunnySacks_Courtyard", Vector2(700.0, 544.0), 0.04)
	_spawn_prop(PROP_SCOOTER_SCENE, "ParkedScooter_Courtyard", Vector2(526.0, 548.0), -0.08)
	_spawn_prop(PROP_BEST_BENCH_SCENE, "BESTBench_BusStop", Vector2(1102.0, 174.0))
	_spawn_prop(PROP_CARDBOARD_BOX_SCENE, "CardboardBox_BusStop", Vector2(1166.0, 444.0), 0.15)
	_spawn_prop(PROP_CARDBOARD_BOX_SCENE, "CardboardBox_LowerLoop", Vector2(996.0, 572.0), -0.10)
	_spawn_prop(PROP_LAUNDRY_LINE_SCENE, "LaundryLinePoles_Loggia", Vector2(832.0, 90.0), 0.03)


func _position_markers() -> void:
	_set_marker_position("Spawn", tuning.spawn_player)
	_set_marker_position("RivalSpawn_Stray", Vector2(592.0, 486.0))
	_set_marker_position("RivalSpawn_Sentry", Vector2(704.0, 286.0))
	_set_marker_position("RivalSpawn_Racer", Vector2(1084.0, 562.0))
	_set_marker_position("RivalSpawn_Bully", Vector2(1118.0, 306.0))
	_set_marker_position("RivalSpawn_A", tuning.spawn_rival_a)
	_set_marker_position("RivalSpawn_B", tuning.spawn_rival_b)


func _spawn_rivals() -> void:
	_clear_children(_rivals)
	for archetype in _get_rival_archetypes():
		_spawn_rival(archetype)


func sync_rival_tuning() -> void:
	for child in _rivals.get_children():
		if child.has_method("sync_tuning"):
			child.call("sync_tuning", tuning)
		elif child.get("tuning") != null:
			child.tuning = tuning


func respawn_rivals() -> void:
	_spawn_rivals()


func _get_rival_archetypes() -> Array[RivalArchetype]:
	var archetypes: Array[RivalArchetype] = []
	var source := rival_archetypes
	if source.is_empty() and tuning != null:
		source = tuning.rival_archetypes
	if source.is_empty():
		archetypes.append(ARCHETYPE_STRAY)
		archetypes.append(ARCHETYPE_SENTRY)
		archetypes.append(ARCHETYPE_RACER)
		archetypes.append(ARCHETYPE_BULLY)
	else:
		for archetype in source:
			if archetype != null:
				archetypes.append(archetype)
	return archetypes


func _spawn_rival(archetype: RivalArchetype) -> void:
	if archetype == null:
		return
	var rival := RIVAL_DOG_SCENE.instantiate() as CharacterBody2D
	rival.name = "RivalDog_%s" % archetype.display_name.replace(" ", "")
	rival.position = get_rival_spawn(archetype.id)
	rival.set("tuning", tuning)
	rival.set("archetype", archetype)
	_rivals.add_child(rival)


func _marker_name_for_archetype(archetype_id: StringName) -> String:
	match archetype_id:
		&"stray":
			return "RivalSpawn_Stray"
		&"sentry":
			return "RivalSpawn_Sentry"
		&"racer":
			return "RivalSpawn_Racer"
		&"bully":
			return "RivalSpawn_Bully"
		_:
			return "RivalSpawn_Stray"


func _fallback_spawn_for_archetype(archetype_id: StringName) -> Vector2:
	match archetype_id:
		&"stray":
			return Vector2(592.0, 486.0)
		&"sentry":
			return Vector2(704.0, 286.0)
		&"racer":
			return Vector2(1084.0, 562.0)
		&"bully":
			return Vector2(1118.0, 306.0)
		_:
			return Vector2(592.0, 486.0)


func _spawn_prop(scene: PackedScene, node_name: String, spawn_position: Vector2, rotation_radians: float = 0.0) -> Node2D:
	var prop := scene.instantiate() as Node2D
	prop.name = node_name
	prop.position = spawn_position
	prop.rotation = rotation_radians
	_props.add_child(prop)
	return prop


func _add_boundary(body_name: String, position: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.position = position
	body.collision_layer = 1
	body.collision_mask = 0

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.position = size * 0.5
	shape_node.shape = shape
	body.add_child(shape_node)
	_add_rect(body, "Visual", Vector2.ZERO, size, color, 0)

	_walls.add_child(body)
	return body


func _add_internal_wall(body_name: String, position: Vector2, size: Vector2) -> StaticBody2D:
	var wall := _add_boundary(body_name, position, size, Color("#11171A"))
	_add_rect(wall, "WetEdge", Vector2(0.0, size.y - 4.0), Vector2(size.x, 4.0), Color(0.95, 0.68, 0.34, 0.12), 1)
	return wall


func _add_floor_zone(node_name: String, position: Vector2, size: Vector2, color: Color) -> void:
	_add_rect(_surface, node_name, position, size, color, -12)
	_add_paver_joints(_surface, position, size)


func _add_chawl_wall() -> void:
	var wall_margin := 36.0
	var wall_width := tuning.arena_width - wall_margin * 2.0
	_add_rect(_dressing, "ChawlWall_WetPlaster", Vector2(wall_margin, 20.0), Vector2(wall_width, 70.0), tuning.chawl_wall_color, 12)
	_add_line(_dressing, "ChawlWire_Main", PackedVector2Array([
		Vector2(54.0, 34.0),
		Vector2(338.0, 42.0),
		Vector2(662.0, 30.0),
		Vector2(1034.0, 44.0),
		Vector2(1232.0, 36.0),
	]), 2.0, Color(0.025, 0.025, 0.025, 0.92), 14)
	var window_count := maxi(10, int((wall_width - 70.0) / 88.0))
	for i in range(window_count):
		var x := 64.0 + float(i) * 88.0
		var lit := i % 3 == 1
		var color := Color(0.9, 0.6, 0.28, 0.66) if lit else Color(0.055, 0.06, 0.065, 1.0)
		_add_rect(_dressing, "ChawlWindow_%02d" % i, Vector2(x, 40.0), Vector2(32.0, 20.0), color, 13)
		_add_rect(_dressing, "WindowDrip_%02d" % i, Vector2(x - 2.0, 64.0), Vector2(36.0, 4.0), Color(0.05, 0.055, 0.06, 0.75), 13)


func _add_puddles() -> void:
	_add_rect(_dressing, "Puddle_MainLaneBlueGrey", Vector2(504.0, 248.0), Vector2(164.0, 42.0), tuning.puddle_color, -3)
	_add_rect(_dressing, "Puddle_MainLaneSheen", Vector2(530.0, 258.0), Vector2(96.0, 7.0), Color(0.5, 0.62, 0.72, 0.24), -2)
	_add_rect(_dressing, "Puddle_CourtyardWide", Vector2(768.0, 474.0), Vector2(132.0, 36.0), Color(0.08, 0.14, 0.19, 0.5), -3)
	_add_rect(_dressing, "Puddle_BusStopCurb", Vector2(1064.0, 226.0), Vector2(96.0, 28.0), Color(0.08, 0.14, 0.19, 0.48), -3)
	_add_line(_dressing, "PuddleCrack", PackedVector2Array([
		Vector2(704.0, 508.0),
		Vector2(678.0, 518.0),
		Vector2(654.0, 512.0),
		Vector2(626.0, 528.0),
	]), 2.0, Color(0.18, 0.17, 0.16, 0.65), -1)


func _add_best_stop_stripe() -> void:
	var stop_x := 1056.0
	_add_rect(_dressing, "BESTStop_GreenStripe", Vector2(stop_x, 118.0), Vector2(136.0, 16.0), tuning.best_green_color, 3)
	_add_rect(_dressing, "BESTStop_AmberTrim", Vector2(stop_x, 134.0), Vector2(136.0, 4.0), Color(0.88, 0.68, 0.28, 0.88), 4)


func _add_corrugated_lip() -> void:
	var wall_margin := 32.0
	var wall_width := tuning.arena_width - wall_margin * 2.0
	_add_rect(_dressing, "CorrugatedShopLip", Vector2(wall_margin, 624.0), Vector2(wall_width, 72.0), tuning.corrugated_lip_color, 12)
	var corrugation_count := int(wall_width / 50.0)
	for i in range(corrugation_count):
		var x := wall_margin + 8.0 + float(i) * 50.0
		_add_rect(_dressing, "Corrugation_%02d" % i, Vector2(x, 624.0), Vector2(4.0, 72.0), Color(0.16, 0.18, 0.18, 0.35), 13)


func _add_light_slices() -> void:
	var pools := [
		Rect2(118.0, 118.0, 78.0, 396.0),
		Rect2(404.0, 128.0, 88.0, 430.0),
		Rect2(710.0, 118.0, 78.0, 430.0),
		Rect2(1082.0, 128.0, 72.0, 370.0),
	]
	for i in range(pools.size()):
		var rect := pools[i] as Rect2
		_add_rect(_dressing, "SodiumLightSlice_%02d" % i, rect.position, rect.size, Color(0.95, 0.55, 0.25, 0.06), -2)


func _add_paver_joints(parent: Node, origin: Vector2, size: Vector2) -> void:
	for i in range(int(ceil(size.x / 48.0))):
		var x := origin.x + float(i) * 48.0
		_add_line(parent, "PaverJointV_%02d" % i, PackedVector2Array([
			Vector2(x, origin.y),
			Vector2(x, origin.y + size.y),
		]), 1.0, Color(0.23, 0.225, 0.2, 0.26), -6)
	for i in range(int(ceil(size.y / 48.0))):
		var y := origin.y + float(i) * 48.0
		_add_line(parent, "PaverJointH_%02d" % i, PackedVector2Array([
			Vector2(origin.x, y),
			Vector2(origin.x + size.x, y),
		]), 1.0, Color(0.23, 0.225, 0.2, 0.2), -6)


func _get_marker_position(marker_name: String, fallback: Vector2) -> Vector2:
	var marker := _spawns.get_node_or_null(marker_name) as Marker2D
	if marker == null:
		return fallback
	return marker.global_position


func _set_marker_position(marker_name: String, position: Vector2) -> void:
	var marker := _spawns.get_node_or_null(marker_name) as Marker2D
	if marker != null:
		marker.position = position


func _place_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		player.global_position = get_spawn_position()


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _add_rect(parent: Node, node_name: String, position: Vector2, size: Vector2, color: Color, z: int = 0) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = position
	rect.size = size
	rect.color = color
	rect.z_index = z
	parent.add_child(rect)
	return rect


func _add_line(parent: Node, node_name: String, points: PackedVector2Array, width: float, color: Color, z: int = 0) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.width = width
	line.default_color = color
	line.z_index = z
	parent.add_child(line)
	return line
