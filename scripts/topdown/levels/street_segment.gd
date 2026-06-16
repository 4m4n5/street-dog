extends Node2D

const STREET_LAMP_SCENE := preload("res://scenes/topdown/props/street_lamp_topdown.tscn")
const PROP_CHAI_COUNTER_SCENE := preload("res://scenes/topdown/props/chai_stall_counter.tscn")
const PROP_PLASTIC_CHAIR_SCENE := preload("res://scenes/topdown/props/plastic_chair.tscn")
const PROP_GUNNY_SACKS_SCENE := preload("res://scenes/topdown/props/gunny_sacks.tscn")
const PROP_SCOOTER_SCENE := preload("res://scenes/topdown/props/parked_scooter.tscn")
const PROP_CARDBOARD_BOX_SCENE := preload("res://scenes/topdown/props/cardboard_box.tscn")
const ARCHETYPE_STRAY := preload("res://resources/topdown/archetypes/stray.tres")
const ARCHETYPE_SENTRY := preload("res://resources/topdown/archetypes/sentry.tres")
const ARCHETYPE_RACER := preload("res://resources/topdown/archetypes/racer.tres")
const ARCHETYPE_BULLY := preload("res://resources/topdown/archetypes/bully.tres")

@export var tuning: TopdownTuning = TopdownTuning.new()
@export var rival_archetypes: Array[RivalArchetype] = []
@export var segment_size: Vector2 = Vector2(1920.0, 1080.0)
@export var lamp_a_position: Vector2 = Vector2(640.0, 500.0)
@export var lamp_b_position: Vector2 = Vector2(1285.0, 470.0)
@export var lamp_a_radius: float = 175.0
@export var lamp_b_radius: float = 185.0

@onready var _canvas_modulate: CanvasModulate = $CanvasModulate
@onready var _surface: Node2D = $Surface
@onready var _walls: Node2D = $Walls
@onready var _dressing: Node2D = $Dressing
@onready var _lights: Node2D = $Lights
@onready var _props: Node2D = $Props
@onready var _spawns: Node2D = $Spawns
@onready var _wave_controller: Node = $StreetWaveController


func _ready() -> void:
	_ensure_tuning()
	add_to_group("topdown_arena")
	add_to_group("street_segment")
	_build_segment()
	_position_markers()
	call_deferred("_place_player")
	call_deferred("apply_player_camera_bounds")


func get_spawn_position() -> Vector2:
	return _get_marker_position("Spawn", Vector2(190.0, 650.0))


func get_rival_spawn(archetype_id: StringName) -> Vector2:
	return get_rival_dark_spawn(archetype_id)


func get_rival_dark_spawn(archetype_id: StringName) -> Vector2:
	return _get_marker_position(_marker_name_for_archetype(archetype_id, true), _fallback_spawn_for_archetype(archetype_id, true))


func get_rival_emerge_position(archetype_id: StringName) -> Vector2:
	return _get_marker_position(_marker_name_for_archetype(archetype_id, false), _fallback_spawn_for_archetype(archetype_id, false))


func get_rival_archetypes() -> Array[RivalArchetype]:
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


func sync_rival_tuning() -> void:
	if _wave_controller != null and _wave_controller.has_method("sync_rival_tuning"):
		_wave_controller.call("sync_rival_tuning")


func respawn_rivals() -> void:
	if _wave_controller != null and _wave_controller.has_method("restart_wave"):
		_wave_controller.call("restart_wave")


func apply_player_camera_bounds() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("set_camera_bounds"):
		player.call("set_camera_bounds", Rect2(global_position, segment_size))


func _ensure_tuning() -> void:
	if tuning == null:
		tuning = TopdownTuning.new()


func _build_segment() -> void:
	_clear_children(_surface)
	_clear_children(_walls)
	_clear_children(_dressing)
	_clear_children(_lights)
	_clear_children(_props)

	if _canvas_modulate != null:
		_canvas_modulate.color = Color(0.30, 0.33, 0.39, 1.0)

	_add_rect(_surface, "NightBase_WetCharcoal", Vector2.ZERO, segment_size, Color("#080A0D"), -60)
	_add_main_run()
	_add_side_gully()
	_add_chai_spill()
	_add_facades()
	_add_wet_detail()
	_add_lamps()
	_add_props()


func _add_main_run() -> void:
	_add_poly(_surface, "WetMainRun_Asphalt", PackedVector2Array([
		Vector2(96.0, 392.0),
		Vector2(728.0, 372.0),
		Vector2(1374.0, 354.0),
		Vector2(1768.0, 392.0),
		Vector2(1744.0, 642.0),
		Vector2(1340.0, 690.0),
		Vector2(1012.0, 660.0),
		Vector2(934.0, 764.0),
		Vector2(820.0, 742.0),
		Vector2(780.0, 656.0),
		Vector2(112.0, 692.0),
	]), Color("#22272A"), -40)
	_add_poly(_surface, "WetMainRun_Sheen", PackedVector2Array([
		Vector2(210.0, 476.0),
		Vector2(734.0, 438.0),
		Vector2(1348.0, 418.0),
		Vector2(1588.0, 462.0),
		Vector2(1380.0, 536.0),
		Vector2(626.0, 562.0),
		Vector2(250.0, 596.0),
	]), Color(0.36, 0.44, 0.50, 0.17), -35)
	for i in range(22):
		var x := 145.0 + float(i) * 76.0
		_add_line(_surface, "MainRunPaverJoint_%02d" % i, PackedVector2Array([
			Vector2(x, 404.0 + sin(float(i)) * 18.0),
			Vector2(x + 28.0, 664.0 + cos(float(i) * 0.8) * 18.0),
		]), 1.0, Color(0.14, 0.16, 0.16, 0.44), -32)


func _add_side_gully() -> void:
	_add_poly(_surface, "DarkSideGully_Surface", PackedVector2Array([
		Vector2(806.0, 648.0),
		Vector2(950.0, 666.0),
		Vector2(1088.0, 840.0),
		Vector2(990.0, 914.0),
		Vector2(820.0, 770.0),
	]), Color("#151A1D"), -39)
	_add_poly(_dressing, "SideGully_DarkWash", PackedVector2Array([
		Vector2(780.0, 654.0),
		Vector2(1088.0, 654.0),
		Vector2(1122.0, 870.0),
		Vector2(1000.0, 962.0),
		Vector2(792.0, 790.0),
	]), Color(0.0, 0.0, 0.0, 0.25), -8)


func _add_chai_spill() -> void:
	_add_poly(_dressing, "ChaiSpill_Decal", PackedVector2Array([
		Vector2(112.0, 562.0),
		Vector2(318.0, 522.0),
		Vector2(420.0, 608.0),
		Vector2(332.0, 704.0),
		Vector2(138.0, 698.0),
	]), Color(0.94, 0.50, 0.20, 0.30), -18)
	_add_poly(_dressing, "ChaiSpill_Core", PackedVector2Array([
		Vector2(164.0, 594.0),
		Vector2(280.0, 568.0),
		Vector2(346.0, 620.0),
		Vector2(286.0, 668.0),
		Vector2(174.0, 660.0),
	]), Color(0.98, 0.62, 0.28, 0.24), -17)


func _add_facades() -> void:
	_add_static_rect("Boundary_NorthDarkChawl", Vector2(0.0, 0.0), Vector2(segment_size.x, 260.0), Color("#090E12"))
	_add_static_rect("Boundary_SouthCorrugatedLip", Vector2(0.0, 802.0), Vector2(segment_size.x, 278.0), Color("#0B1013"))
	_add_static_rect("Boundary_WestShopBacks", Vector2(0.0, 0.0), Vector2(96.0, segment_size.y), Color("#070B0E"))
	_add_static_rect("Boundary_EastShopBacks", Vector2(1818.0, 0.0), Vector2(102.0, segment_size.y), Color("#070B0E"))

	_add_static_rect("Facade_NorthForkShoulder", Vector2(884.0, 260.0), Vector2(254.0, 82.0), Color("#10181B"))
	_add_static_rect("Facade_NorthEastShoulder", Vector2(1450.0, 250.0), Vector2(368.0, 120.0), Color("#0D1417"))
	_add_static_rect("Facade_WestChaiShoulder", Vector2(96.0, 260.0), Vector2(230.0, 118.0), Color("#111519"))
	_add_static_rect("Facade_SideGullyWestMass", Vector2(690.0, 664.0), Vector2(112.0, 150.0), Color("#0D1215"))
	_add_static_rect("Facade_SideGullyEastMass", Vector2(1020.0, 656.0), Vector2(202.0, 166.0), Color("#0D1215"))
	_add_static_rect("Facade_EastGullyShoulder", Vector2(1518.0, 646.0), Vector2(300.0, 156.0), Color("#0B1114"))


func _add_wet_detail() -> void:
	_add_rect(_dressing, "Puddle_LampA_WarmCatch", Vector2(554.0, 564.0), Vector2(148.0, 28.0), Color(0.96, 0.62, 0.32, 0.15), -16)
	_add_rect(_dressing, "Puddle_LampB_WarmCatch", Vector2(1228.0, 548.0), Vector2(180.0, 32.0), Color(0.96, 0.62, 0.32, 0.14), -16)
	_add_rect(_dressing, "Puddle_DarkGapBlue", Vector2(890.0, 518.0), Vector2(190.0, 30.0), Color(0.08, 0.15, 0.20, 0.46), -16)
	_add_line(_dressing, "Crack_MainRun_00", PackedVector2Array([
		Vector2(430.0, 628.0),
		Vector2(520.0, 610.0),
		Vector2(602.0, 626.0),
		Vector2(688.0, 602.0),
	]), 2.0, Color(0.06, 0.07, 0.07, 0.58), -15)
	_add_line(_dressing, "OverheadWire_Dark", PackedVector2Array([
		Vector2(320.0, 286.0),
		Vector2(640.0, 312.0),
		Vector2(1020.0, 292.0),
		Vector2(1440.0, 320.0),
	]), 2.0, Color(0.02, 0.022, 0.024, 0.86), 20)


func _add_lamps() -> void:
	_spawn_lamp("StreetLamp_LAMP_A", lamp_a_position, lamp_a_radius, 1.55)
	_spawn_lamp("StreetLamp_LAMP_B", lamp_b_position, lamp_b_radius, 1.62)


func _add_props() -> void:
	_spawn_prop(PROP_CHAI_COUNTER_SCENE, "ChaiCounter_SpillFoothold", Vector2(230.0, 610.0), -0.05)
	_spawn_prop(PROP_PLASTIC_CHAIR_SCENE, "PlasticChair_LampAEdge", Vector2(590.0, 540.0), -0.25)
	_spawn_prop(PROP_GUNNY_SACKS_SCENE, "GunnySacks_SideGullyMouth", Vector2(890.0, 640.0), 0.08)
	_spawn_prop(PROP_SCOOTER_SCENE, "ParkedScooter_LampBEdge", Vector2(1340.0, 560.0), -0.18)
	_spawn_prop(PROP_CARDBOARD_BOX_SCENE, "CardboardBox_EastShoulder", Vector2(1495.0, 635.0), 0.14)


func _spawn_lamp(node_name: String, lamp_position: Vector2, radius: float, energy: float) -> void:
	var lamp := STREET_LAMP_SCENE.instantiate() as Node2D
	lamp.name = node_name
	lamp.position = lamp_position
	_lights.add_child(lamp)
	if lamp.has_method("configure"):
		lamp.call("configure", radius, energy, Color("#F28E42"))


func _spawn_prop(scene: PackedScene, node_name: String, prop_position: Vector2, rotation_radians: float = 0.0) -> Node2D:
	var prop := scene.instantiate() as Node2D
	prop.name = node_name
	prop.position = prop_position
	prop.rotation = rotation_radians
	_props.add_child(prop)
	return prop


func _position_markers() -> void:
	_set_marker_position("Spawn", Vector2(190.0, 650.0))
	_set_marker_position("RivalSpawn_Stray", Vector2(430.0, 710.0))
	_set_marker_position("RivalSpawn_Sentry", Vector2(1050.0, 340.0))
	_set_marker_position("RivalSpawn_Racer", Vector2(1610.0, 655.0))
	_set_marker_position("RivalSpawn_Bully", Vector2(1690.0, 575.0))
	_set_marker_position("Emerge_Stray", Vector2(585.0, 525.0))
	_set_marker_position("Emerge_Sentry", Vector2(1005.0, 500.0))
	_set_marker_position("Emerge_Racer", Vector2(1325.0, 525.0))
	_set_marker_position("Emerge_Bully", Vector2(1395.0, 500.0))


func _marker_name_for_archetype(archetype_id: StringName, dark_spawn: bool) -> String:
	var prefix := "RivalSpawn_" if dark_spawn else "Emerge_"
	match archetype_id:
		&"stray":
			return prefix + "Stray"
		&"sentry":
			return prefix + "Sentry"
		&"racer":
			return prefix + "Racer"
		&"bully":
			return prefix + "Bully"
		_:
			return prefix + "Stray"


func _fallback_spawn_for_archetype(archetype_id: StringName, dark_spawn: bool) -> Vector2:
	match archetype_id:
		&"stray":
			return Vector2(430.0, 710.0) if dark_spawn else Vector2(585.0, 525.0)
		&"sentry":
			return Vector2(1050.0, 340.0) if dark_spawn else Vector2(1005.0, 500.0)
		&"racer":
			return Vector2(1610.0, 655.0) if dark_spawn else Vector2(1325.0, 525.0)
		&"bully":
			return Vector2(1690.0, 575.0) if dark_spawn else Vector2(1395.0, 500.0)
		_:
			return Vector2(430.0, 710.0) if dark_spawn else Vector2(585.0, 525.0)


func _get_marker_position(marker_name: String, fallback: Vector2) -> Vector2:
	var marker := _spawns.get_node_or_null(marker_name) as Marker2D
	if marker == null:
		return fallback
	return marker.global_position


func _set_marker_position(marker_name: String, marker_position: Vector2) -> void:
	var marker := _spawns.get_node_or_null(marker_name) as Marker2D
	if marker != null:
		marker.position = marker_position


func _place_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		player.global_position = get_spawn_position()


func _add_static_rect(body_name: String, rect_position: Vector2, rect_size: Vector2, color: Color) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = body_name
	body.position = rect_position
	body.collision_layer = 1
	body.collision_mask = 0

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect_size
	shape_node.position = rect_size * 0.5
	shape_node.shape = shape
	body.add_child(shape_node)

	_add_rect(body, "Visual", Vector2.ZERO, rect_size, color, 0)
	_add_occluder(body, rect_size)
	_walls.add_child(body)
	return body


func _add_occluder(parent: Node2D, size: Vector2) -> void:
	var occluder := LightOccluder2D.new()
	occluder.name = "LightOccluder2D"
	var polygon := OccluderPolygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0.0),
		size,
		Vector2(0.0, size.y),
	])
	occluder.occluder = polygon
	parent.add_child(occluder)


func _add_rect(parent: Node, node_name: String, rect_position: Vector2, rect_size: Vector2, color: Color, z: int = 0) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.position = rect_position
	rect.size = rect_size
	rect.color = color
	rect.z_index = z
	parent.add_child(rect)
	return rect


func _add_poly(parent: Node, node_name: String, points: PackedVector2Array, color: Color, z: int = 0) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = node_name
	poly.polygon = points
	poly.color = color
	poly.z_index = z
	parent.add_child(poly)
	return poly


func _add_line(parent: Node, node_name: String, points: PackedVector2Array, width: float, color: Color, z: int = 0) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.width = width
	line.default_color = color
	line.z_index = z
	parent.add_child(line)
	return line


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()
