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
	var top_depth := 88.0
	var bottom_depth := 92.0
	var side_depth := tuning.wall_inset
	_add_rect(_surface, "RainDarkAsphalt", Vector2.ZERO, size, Color("#090B0D"), -20)
	_add_floor_zone("Node_NukkadChaiFoothold", Vector2(44.0, 448.0), Vector2(228.0, 180.0), Color("#28251F"))
	_add_floor_zone("Lane_MainGullyWetRun", Vector2(270.0, 408.0), Vector2(206.0, 220.0), Color("#2E2B26"))
	_add_floor_zone("Node_GullyFork", Vector2(418.0, 292.0), Vector2(204.0, 248.0), Color("#302D28"))
	_add_floor_zone("Node_WadiChowk", Vector2(604.0, 300.0), Vector2(304.0, 224.0), Color("#292721"))
	_add_floor_zone("Lane_ByLaneLaundryCut", Vector2(646.0, 540.0), Vector2(368.0, 88.0), Color("#242827"))
	_add_floor_zone("Lane_WadiToBestMouth", Vector2(872.0, 360.0), Vector2(96.0, 128.0), Color("#2B2A24"))
	_add_floor_zone("Node_BESTChowkBusStrip", Vector2(944.0, 244.0), Vector2(284.0, 236.0), Color("#202923"))

	_add_boundary("BoundaryTop_ChawlSkyline", Vector2.ZERO, Vector2(tuning.arena_width, top_depth), tuning.gully_wall_color)
	_add_boundary("BoundaryBottom_CorrugatedShopEdge", Vector2(0.0, tuning.arena_height - bottom_depth), Vector2(tuning.arena_width, bottom_depth), tuning.corrugated_lip_color)
	_add_boundary("BoundaryLeft_Shopbacks", Vector2.ZERO, Vector2(side_depth, tuning.arena_height), tuning.gully_wall_color)
	_add_boundary("BoundaryRight_BusDepotEdge", Vector2(tuning.arena_width - side_depth, 0.0), Vector2(side_depth, tuning.arena_height), tuning.gully_wall_color)
	_add_building_footprints()

	_add_chawl_wall()
	_add_chawl_stairs()
	_add_wire_drip_elements()
	_add_puddles()
	_add_best_stop_stripe()
	_add_corrugated_lip()
	_add_light_slices()


func _build_props() -> void:
	_clear_children(_props)
	_spawn_prop(PROP_CHAI_COUNTER_SCENE, "ChaiStallCounter_Nukkad", Vector2(158.0, 496.0))
	_spawn_prop(PROP_PLASTIC_CHAIR_SCENE, "PlasticChair_MainGullyMouth", Vector2(354.0, 458.0), -0.16)
	_spawn_prop(PROP_GUNNY_SACKS_SCENE, "GunnySacks_ForkShoulder", Vector2(456.0, 372.0), 0.08)
	_spawn_prop(PROP_SCOOTER_SCENE, "ParkedScooter_WadiEdge", Vector2(760.0, 448.0), -0.10)
	_spawn_prop(PROP_BEST_BENCH_SCENE, "BESTBench_ChowkStrip", Vector2(1102.0, 292.0))
	_spawn_prop(PROP_CARDBOARD_BOX_SCENE, "CardboardBox_BESTCurb", Vector2(1018.0, 430.0), 0.15)
	_spawn_prop(PROP_CARDBOARD_BOX_SCENE, "CardboardBox_ByLaneRear", Vector2(880.0, 586.0), -0.10)
	_spawn_prop(PROP_LAUNDRY_LINE_SCENE, "LaundryLinePoles_ByLaneMouth", Vector2(710.0, 548.0), 0.03)


func _position_markers() -> void:
	_set_marker_position("Spawn", tuning.spawn_player)
	_set_marker_position("RivalSpawn_Stray", Vector2(704.0, 404.0))
	_set_marker_position("RivalSpawn_Sentry", Vector2(558.0, 334.0))
	_set_marker_position("RivalSpawn_Racer", Vector2(846.0, 586.0))
	_set_marker_position("RivalSpawn_Bully", Vector2(1092.0, 348.0))
	_set_marker_position("RivalSpawn_A", Vector2(704.0, 404.0))
	_set_marker_position("RivalSpawn_B", Vector2(1092.0, 348.0))


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
			return Vector2(704.0, 404.0)
		&"sentry":
			return Vector2(558.0, 334.0)
		&"racer":
			return Vector2(846.0, 586.0)
		&"bully":
			return Vector2(1092.0, 348.0)
		_:
			return Vector2(704.0, 404.0)


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


func _add_floor_zone(node_name: String, position: Vector2, size: Vector2, color: Color) -> void:
	_add_rect(_surface, node_name, position, size, color, -12)
	_add_paver_joints(_surface, position, size)


func _add_building_footprints() -> void:
	_add_footprint("Footprint_WestShopBlock_ChaiShoulder", Vector2(32.0, 88.0), Vector2(238.0, 356.0), Color("#12191B"))
	_add_footprint("Footprint_NorthChawl_LongFacade", Vector2(470.0, 88.0), Vector2(338.0, 192.0), tuning.chawl_wall_color)
	_add_footprint("Footprint_EastChawl_BusBack", Vector2(1014.0, 88.0), Vector2(234.0, 142.0), Color("#111A18"))
	_add_footprint("Footprint_ForkCornerClinic", Vector2(500.0, 432.0), Vector2(92.0, 108.0), Color("#141B1C"))
	_add_footprint("Footprint_WadiSouthWorkshop", Vector2(438.0, 540.0), Vector2(208.0, 88.0), Color("#111719"))
	_add_footprint("Footprint_BESTDepotKiosk", Vector2(1128.0, 474.0), Vector2(120.0, 154.0), Color("#0F1717"))


func _add_footprint(body_name: String, position: Vector2, size: Vector2, color: Color) -> StaticBody2D:
	var body := _add_boundary(body_name, position, size, color)
	_add_rect(body, "OpenSkyShadow", Vector2.ZERO, Vector2(size.x, 8.0), Color(0.0, 0.0, 0.0, 0.28), 1)
	_add_rect(body, "WetFacadeLip", Vector2(0.0, size.y - 5.0), Vector2(size.x, 5.0), Color(0.95, 0.68, 0.34, 0.12), 1)
	return body


func _add_chawl_wall() -> void:
	var wall_margin := 36.0
	var wall_width := tuning.arena_width - wall_margin * 2.0
	_add_rect(_dressing, "ChawlFacade_WetPlaster", Vector2(wall_margin, 18.0), Vector2(wall_width, 66.0), tuning.chawl_wall_color, 12)
	_add_rect(_dressing, "ChawlLoggia_DarkRail", Vector2(470.0, 82.0), Vector2(338.0, 10.0), Color(0.035, 0.035, 0.032, 0.92), 15)
	var window_count := maxi(10, int((wall_width - 70.0) / 88.0))
	for i in range(window_count):
		var x := 64.0 + float(i) * 88.0
		var lit := i % 3 == 1
		var color := Color(0.9, 0.6, 0.28, 0.66) if lit else Color(0.055, 0.06, 0.065, 1.0)
		_add_rect(_dressing, "ChawlWindow_%02d" % i, Vector2(x, 40.0), Vector2(32.0, 20.0), color, 13)
		_add_rect(_dressing, "WindowDripLip_%02d" % i, Vector2(x - 2.0, 64.0), Vector2(36.0, 4.0), Color(0.05, 0.055, 0.06, 0.75), 13)


func _add_chawl_stairs() -> void:
	_add_rect(_dressing, "ChawlLoggiaStair_Landing", Vector2(816.0, 94.0), Vector2(64.0, 18.0), Color(0.13, 0.12, 0.10, 0.92), 12)
	for i in range(6):
		var step_position := Vector2(820.0 + float(i) * 8.0, 112.0 + float(i) * 12.0)
		var step_size := Vector2(64.0 - float(i) * 6.0, 8.0)
		_add_rect(_dressing, "ChawlLoggiaStair_Step_%02d" % i, step_position, step_size, Color(0.15, 0.14, 0.12, 0.88), 12)

	var ring_color := Color(0.11, 0.10, 0.085, 0.78)
	_add_rect(_dressing, "WadiRingStep_North", Vector2(622.0, 300.0), Vector2(240.0, 10.0), ring_color, 2)
	_add_rect(_dressing, "WadiRingStep_South", Vector2(630.0, 510.0), Vector2(218.0, 10.0), ring_color, 2)
	_add_rect(_dressing, "WadiRingStep_West", Vector2(604.0, 330.0), Vector2(10.0, 152.0), ring_color, 2)
	_add_rect(_dressing, "WadiRingStep_East", Vector2(890.0, 326.0), Vector2(10.0, 168.0), ring_color, 2)


func _add_wire_drip_elements() -> void:
	_add_line(_dressing, "WireTangle_NukkadToFork", PackedVector2Array([
		Vector2(222.0, 122.0),
		Vector2(316.0, 168.0),
		Vector2(424.0, 150.0),
		Vector2(536.0, 188.0),
	]), 2.0, Color(0.025, 0.025, 0.025, 0.92), 14)
	_add_line(_dressing, "WireTangle_WadiLaundry", PackedVector2Array([
		Vector2(610.0, 286.0),
		Vector2(698.0, 264.0),
		Vector2(792.0, 282.0),
		Vector2(906.0, 256.0),
	]), 2.0, Color(0.025, 0.025, 0.025, 0.9), 14)
	_add_line(_dressing, "WireTangle_BESTChowk", PackedVector2Array([
		Vector2(1004.0, 234.0),
		Vector2(1086.0, 214.0),
		Vector2(1180.0, 236.0),
		Vector2(1238.0, 220.0),
	]), 2.0, Color(0.025, 0.025, 0.025, 0.88), 14)

	var drip_color := Color(0.42, 0.52, 0.58, 0.28)
	_add_line(_dressing, "WireDrip_Nukkad_00", PackedVector2Array([Vector2(338.0, 168.0), Vector2(338.0, 196.0)]), 1.0, drip_color, 13)
	_add_line(_dressing, "WireDrip_Wadi_00", PackedVector2Array([Vector2(744.0, 274.0), Vector2(744.0, 318.0)]), 1.0, drip_color, 13)
	_add_line(_dressing, "WireDrip_BEST_00", PackedVector2Array([Vector2(1136.0, 226.0), Vector2(1136.0, 264.0)]), 1.0, drip_color, 13)


func _add_puddles() -> void:
	_add_rect(_dressing, "Puddle_MainGullyBlueGrey", Vector2(330.0, 504.0), Vector2(114.0, 34.0), tuning.puddle_color, -3)
	_add_rect(_dressing, "Puddle_MainGullySheen", Vector2(350.0, 512.0), Vector2(74.0, 6.0), Color(0.5, 0.62, 0.72, 0.24), -2)
	_add_rect(_dressing, "Puddle_WadiWide", Vector2(750.0, 476.0), Vector2(128.0, 34.0), Color(0.08, 0.14, 0.19, 0.5), -3)
	_add_rect(_dressing, "Puddle_BESTCurb", Vector2(1028.0, 390.0), Vector2(96.0, 28.0), Color(0.08, 0.14, 0.19, 0.48), -3)
	_add_line(_dressing, "PuddleCrack", PackedVector2Array([
		Vector2(692.0, 506.0),
		Vector2(670.0, 518.0),
		Vector2(642.0, 512.0),
		Vector2(616.0, 528.0),
	]), 2.0, Color(0.18, 0.17, 0.16, 0.65), -1)


func _add_best_stop_stripe() -> void:
	var stop_x := 1016.0
	_add_rect(_dressing, "BESTStop_GreenStripe", Vector2(stop_x, 250.0), Vector2(180.0, 18.0), tuning.best_green_color, 3)
	_add_rect(_dressing, "BESTStop_AmberTrim", Vector2(stop_x, 268.0), Vector2(180.0, 4.0), Color(0.88, 0.68, 0.28, 0.88), 4)


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
		Rect2(112.0, 448.0, 88.0, 164.0),
		Rect2(336.0, 398.0, 82.0, 214.0),
		Rect2(676.0, 308.0, 92.0, 208.0),
		Rect2(1074.0, 252.0, 78.0, 224.0),
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
