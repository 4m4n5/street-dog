extends Node2D

## Combat-first rainy Mumbai street blockout. Platforms stay solid and street-plausible.

const KILL_ZONE_SCRIPT := preload("res://scripts/levels/kill_zone.gd")
const ARENA_ZONE_SCRIPT := preload("res://scripts/levels/arena_zone.gd")
const HURTBOX_DUMMY_SCENE := preload("res://scenes/enemies/hurtbox_dummy.tscn")
const STREET_ENEMY_SCENE := preload("res://scenes/enemies/street_enemy.tscn")
const HurtboxDummyScript := preload("res://scripts/enemies/hurtbox_dummy.gd")

const ROOM_DATA: Array[Dictionary] = [
	{"id": "A", "name": "Chawl Lane", "x": 0.0, "width": 520.0},
	{"id": "B", "name": "Khau Galli", "x": 700.0, "width": 650.0},
	{"id": "C", "name": "Bus Stop", "x": 1580.0, "width": 560.0},
	{"id": "D", "name": "Block End", "x": 2344.0, "width": 456.0},
]

const PLATFORM_DATA: Array[Dictionary] = [
	{"name": "RoomA_ChawlFootpath", "kind": "footpath", "pos": Vector2(0.0, 520.0), "size": Vector2(520.0, 32.0), "color": Color(0.15, 0.145, 0.13)},
	{"name": "ConnectorAB_WestCurb", "kind": "curb", "pos": Vector2(520.0, 520.0), "size": Vector2(64.0, 32.0), "color": Color(0.13, 0.125, 0.115)},
	{"name": "ConnectorAB_EastCurb", "kind": "curb", "pos": Vector2(646.0, 520.0), "size": Vector2(54.0, 32.0), "color": Color(0.13, 0.125, 0.115)},
	{"name": "RoomB_KhauGalliFootpath", "kind": "footpath", "pos": Vector2(700.0, 520.0), "size": Vector2(650.0, 32.0), "color": Color(0.155, 0.15, 0.135)},
	{"name": "RoomB_ChaiStallCounter", "kind": "stall_counter", "pos": Vector2(930.0, 456.0), "size": Vector2(180.0, 20.0), "color": Color(0.18, 0.105, 0.045), "edge_color": Color(0.95, 0.62, 0.28, 0.72)},
	{"name": "ConnectorBC_CurbStrip", "kind": "curb", "pos": Vector2(1350.0, 520.0), "size": Vector2(230.0, 32.0), "color": Color(0.125, 0.125, 0.115)},
	{"name": "RoomC_BusStopFootpath", "kind": "footpath", "pos": Vector2(1580.0, 520.0), "size": Vector2(560.0, 32.0), "color": Color(0.15, 0.14, 0.13)},
	{"name": "RoomC_ShelterBenchLedge", "kind": "shelter_ledge", "pos": Vector2(1810.0, 456.0), "size": Vector2(150.0, 20.0), "color": Color(0.055, 0.21, 0.18), "edge_color": Color(0.88, 0.68, 0.28, 0.8)},
	{"name": "ConnectorCD_BrokenCurb", "kind": "curb", "pos": Vector2(2140.0, 520.0), "size": Vector2(126.0, 32.0), "color": Color(0.125, 0.12, 0.11)},
	{"name": "RoomD_BarricadeFootpath", "kind": "footpath", "pos": Vector2(2344.0, 520.0), "size": Vector2(456.0, 32.0), "color": Color(0.155, 0.15, 0.14)},
]

const POTHOLE_DATA: Array[Dictionary] = [
	{"name": "OpenManhole_AB", "pos": Vector2(584.0, 520.0), "size": Vector2(62.0, 48.0), "kind": "manhole"},
	{"name": "MonsoonPothole_CD", "pos": Vector2(2266.0, 520.0), "size": Vector2(78.0, 48.0), "kind": "pothole"},
]


func _ready() -> void:
	_build_playfield()
	_build_potholes()
	_build_edge_walls()
	_build_arena_zones()
	_build_room_dressing()
	_build_hazard_warnings()
	_build_l2_access()
	_spawn_enemies()
	_spawn_attackable_props()
	_shimmer_windows()
	call_deferred("_place_player")


func _build_playfield() -> void:
	var playfield := $Playfield
	_clear_children(playfield)
	for data in PLATFORM_DATA:
		playfield.add_child(_make_platform(data))


func _build_potholes() -> void:
	var hazards := $Hazards
	_clear_children(hazards)
	for data in POTHOLE_DATA:
		hazards.add_child(_make_pothole(data))


func _build_room_dressing() -> void:
	var dressing := $Dressing
	_clear_children(dressing)

	_add_vendor_cart_choke(dressing, Vector2(438.0, 480.0))
	_add_zebra_crossing(dressing, 610.0)
	_add_auto_rickshaw(dressing, Vector2(790.0, 486.0))
	_add_scooter_cluster(dressing, Vector2(1120.0, 492.0))
	_add_chai_stall(dressing, Vector2(910.0, 428.0))
	_add_kirana_shutter(dressing, Vector2(1430.0, 462.0))
	_add_bmc_bin(dressing, Vector2(1510.0, 492.0))
	_add_bus_shelter(dressing, Vector2(1760.0, 448.0))
	_add_paan_shop_shutter(dressing, Vector2(1990.0, 464.0))
	_add_speed_breaker(dressing, 2190.0)
	_add_bamboo_barricade(dressing, Vector2(2700.0, 486.0))
	_add_line(dressing, "FinaleMonsoonGleam", PackedVector2Array([
		Vector2(2380.0, 568.0),
		Vector2(2740.0, 568.0),
	]), 2.0, Color(0.55, 0.64, 0.76, 0.18), 2)


func _make_platform(data: Dictionary) -> StaticBody2D:
	var platform_name: String = data["name"]
	var platform_kind: String = data.get("kind", "footpath")
	var position: Vector2 = data["pos"]
	var size: Vector2 = data["size"]
	var color: Color = data["color"]
	var edge_color: Color = data.get("edge_color", Color(0.28, 0.3, 0.34, 0.55))

	var platform := StaticBody2D.new()
	platform.name = "Platform_%s" % platform_name
	platform.collision_layer = 1
	platform.collision_mask = 0
	platform.position = position

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	shape_node.position = size * 0.5
	shape_node.shape = shape
	platform.add_child(shape_node)

	_add_rect(platform, "Visual", Vector2.ZERO, size, color, 0)
	_add_rect(platform, "WetTopEdge", Vector2(0.0, -2.0), Vector2(size.x, 2.0), edge_color, 1)

	if platform_kind == "footpath":
		_add_footpath_details(platform, size)
		_add_rect(platform, "KerbEdge", Vector2(0.0, size.y - 4.0), Vector2(size.x, 4.0), Color(0.2, 0.19, 0.17, 0.9), 2)
	elif platform_kind == "curb":
		_add_curb_details(platform, size)
	elif platform_kind == "stall_counter":
		_add_stall_counter_details(platform, size)
	elif platform_kind == "shelter_ledge":
		_add_shelter_ledge_details(platform, size)

	return platform


func _make_pothole(data: Dictionary) -> Area2D:
	var hole_name: String = data["name"]
	var position: Vector2 = data["pos"]
	var size: Vector2 = data["size"]

	var hazard := Area2D.new()
	hazard.name = hole_name
	hazard.position = position
	hazard.collision_layer = 0
	hazard.collision_mask = 2
	hazard.set_script(KILL_ZONE_SCRIPT)
	hazard.set("spawn_path", NodePath("../../Spawn"))

	var hazard_kind: String = data.get("kind", "pothole")
	var recess_color := Color(0.01, 0.014, 0.022, 1.0)
	_add_rect(hazard, "DarkRecess", Vector2.ZERO, size, recess_color, 0)
	if hazard_kind == "manhole":
		_add_rect(hazard, "BrokenCoverRingTop", Vector2(6.0, 4.0), Vector2(size.x - 12.0, 5.0), Color(0.18, 0.19, 0.18, 0.9), 1)
		_add_rect(hazard, "BrokenCoverRingBottom", Vector2(10.0, size.y - 9.0), Vector2(size.x - 20.0, 5.0), Color(0.16, 0.17, 0.17, 0.86), 1)
		_add_rect(hazard, "LooseCoverPlate", Vector2(size.x - 22.0, 12.0), Vector2(18.0, 20.0), Color(0.08, 0.085, 0.09, 0.95), 2)
	else:
		_add_rect(hazard, "WaterSheen", Vector2(10.0, 10.0), Vector2(size.x - 18.0, 14.0), Color(0.2, 0.35, 0.42, 0.42), 1)
		_add_rect(hazard, "WetLip", Vector2(0.0, -3.0), Vector2(size.x, 3.0), Color(0.35, 0.42, 0.48, 0.35), 1)
	_add_line(hazard, "CrackedWestEdge", PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(-14.0, 8.0),
		Vector2(-4.0, 18.0),
		Vector2(-20.0, 30.0),
	]), 2.0, Color(0.18, 0.19, 0.21, 1.0), 2)
	_add_line(hazard, "CrackedEastEdge", PackedVector2Array([
		Vector2(size.x, 0.0),
		Vector2(size.x + 16.0, 10.0),
		Vector2(size.x + 2.0, 22.0),
		Vector2(size.x + 18.0, 34.0),
	]), 2.0, Color(0.18, 0.19, 0.21, 1.0), 2)

	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(size.x, 180.0)
	shape_node.position = Vector2(size.x * 0.5, 108.0)
	shape_node.shape = shape
	hazard.add_child(shape_node)

	return hazard


func _build_edge_walls() -> void:
	var bounds := $Playfield
	for side in [-1, 1]:
		var wall := StaticBody2D.new()
		wall.name = "EdgeWall_%s" % ("Left" if side < 0 else "Right")
		wall.collision_layer = 1
		wall.collision_mask = 0
		wall.position = Vector2(-16.0 if side < 0 else 2800.0, 480.0)

		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(32.0, 320.0)
		shape_node.position = Vector2(16.0, 160.0)
		shape_node.shape = shape
		wall.add_child(shape_node)
		bounds.add_child(wall)


func _build_arena_zones() -> void:
	var zones := $ArenaZones
	_clear_children(zones)
	for room in ROOM_DATA:
		var zone := Area2D.new()
		zone.name = "Arena_%s" % room["id"]
		zone.collision_layer = 0
		zone.collision_mask = 0
		zone.position = Vector2(room["x"], 468.0)
		zone.set_script(ARENA_ZONE_SCRIPT)
		zone.set("room_id", room["id"])
		zone.set("display_name", room["name"])

		var shape_node := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(room["width"], 120.0)
		shape_node.position = Vector2(room["width"] * 0.5, 60.0)
		shape_node.shape = shape
		zone.add_child(shape_node)
		zones.add_child(zone)


func _build_hazard_warnings() -> void:
	var dressing := $Dressing
	for data in POTHOLE_DATA:
		var pos: Vector2 = data["pos"]
		var size: Vector2 = data["size"]
		_add_line(dressing, "%s_ApproachCrack" % data["name"], PackedVector2Array([
			pos + Vector2(-28.0, -2.0),
			pos + Vector2(-8.0, 6.0),
			pos + Vector2(size.x * 0.5, -4.0),
			pos + Vector2(size.x + 8.0, 4.0),
			pos + Vector2(size.x + 24.0, -2.0),
		]), 1.5, Color(0.22, 0.2, 0.18, 0.55), 3)


func _build_l2_access() -> void:
	var dressing := $Dressing
	_add_rect(dressing, "ChaiStall_Step", Vector2(918.0, 496.0), Vector2(28.0, 24.0), Color(0.14, 0.13, 0.12, 1.0), 4)
	_add_rect(dressing, "ShelterBench_Step", Vector2(1798.0, 496.0), Vector2(24.0, 24.0), Color(0.12, 0.11, 0.1, 1.0), 4)
	for i in range(3):
		_add_rect(dressing, "ChaiStall_Tread%s" % i, Vector2(920.0 + float(i) * 8.0, 500.0 - float(i) * 8.0), Vector2(22.0, 6.0), Color(0.18, 0.16, 0.14, 1.0), 5)
	for i in range(3):
		_add_rect(dressing, "ShelterBench_Tread%s" % i, Vector2(1800.0 + float(i) * 7.0, 500.0 - float(i) * 8.0), Vector2(20.0, 6.0), Color(0.16, 0.15, 0.13, 1.0), 5)


func _add_footpath_details(platform: Node, size: Vector2) -> void:
	var tile_width := 46.0
	var tile_count := int(ceil(size.x / tile_width))
	for i in range(tile_count):
		var x := float(i) * tile_width
		_add_line(platform, "PaverJoint%s" % i, PackedVector2Array([
			Vector2(x, 4.0),
			Vector2(x, size.y - 3.0),
		]), 1.0, Color(0.23, 0.225, 0.2, 0.28), 2)


func _add_curb_details(platform: Node, size: Vector2) -> void:
	for i in range(int(ceil(size.x / 42.0))):
		var x := float(i) * 42.0
		_add_rect(platform, "CurbStripe%s" % i, Vector2(x, 12.0), Vector2(20.0, 4.0), Color(0.72, 0.64, 0.42, 0.28), 2)


func _add_stall_counter_details(platform: Node, size: Vector2) -> void:
	_add_rect(platform, "SteelServingTop", Vector2(0.0, -4.0), Vector2(size.x, 5.0), Color(0.65, 0.62, 0.55, 0.82), 2)
	for i in range(4):
		_add_rect(platform, "TeaGlass%s" % i, Vector2(26.0 + float(i) * 28.0, -15.0), Vector2(8.0, 11.0), Color(0.95, 0.54, 0.24, 0.8), 3)


func _add_shelter_ledge_details(platform: Node, size: Vector2) -> void:
	_add_rect(platform, "BenchSeat", Vector2(0.0, -6.0), Vector2(size.x, 6.0), Color(0.12, 0.32, 0.28, 1.0), 2)
	for i in range(3):
		_add_rect(platform, "BenchLeg%s" % i, Vector2(18.0 + float(i) * 48.0, size.y), Vector2(6.0, 26.0), Color(0.08, 0.1, 0.09, 0.8), 1)


func _add_vendor_cart_choke(parent: Node, position: Vector2) -> void:
	_add_rect(parent, "RoomA_PushcartDeck", position + Vector2(0.0, 28.0), Vector2(92.0, 18.0), Color(0.26, 0.12, 0.045, 1.0), 2)
	_add_rect(parent, "RoomA_PushcartCrateA", position + Vector2(8.0, 6.0), Vector2(32.0, 24.0), Color(0.72, 0.36, 0.12, 1.0), 3)
	_add_rect(parent, "RoomA_PushcartCrateB", position + Vector2(44.0, 0.0), Vector2(34.0, 30.0), Color(0.12, 0.46, 0.18, 1.0), 3)
	_add_rect(parent, "RoomA_PushcartWheelA", position + Vector2(12.0, 44.0), Vector2(14.0, 8.0), Color(0.02, 0.018, 0.015, 1.0), 4)
	_add_rect(parent, "RoomA_PushcartWheelB", position + Vector2(64.0, 44.0), Vector2(14.0, 8.0), Color(0.02, 0.018, 0.015, 1.0), 4)


func _add_auto_rickshaw(parent: Node, position: Vector2) -> void:
	_add_rect(parent, "AutoRickshaw_YellowRoof", position + Vector2(30.0, -24.0), Vector2(82.0, 24.0), Color(0.95, 0.72, 0.12, 1.0), 3)
	_add_rect(parent, "AutoRickshaw_BlackCabin", position + Vector2(18.0, 0.0), Vector2(112.0, 34.0), Color(0.025, 0.028, 0.024, 1.0), 2)
	_add_polygon(parent, "AutoRickshaw_SlantNose", PackedVector2Array([
		position + Vector2(130.0, 0.0),
		position + Vector2(164.0, 14.0),
		position + Vector2(160.0, 34.0),
		position + Vector2(130.0, 34.0),
	]), Color(0.03, 0.034, 0.028, 1.0), 2)
	_add_rect(parent, "AutoRickshaw_Window", position + Vector2(48.0, -16.0), Vector2(44.0, 18.0), Color(0.07, 0.12, 0.12, 0.9), 4)
	_add_rect(parent, "AutoRickshaw_WheelA", position + Vector2(34.0, 30.0), Vector2(24.0, 10.0), Color(0.01, 0.012, 0.01, 1.0), 4)
	_add_rect(parent, "AutoRickshaw_WheelB", position + Vector2(118.0, 30.0), Vector2(24.0, 10.0), Color(0.01, 0.012, 0.01, 1.0), 4)


func _add_scooter_cluster(parent: Node, position: Vector2) -> void:
	for i in range(3):
		var offset := Vector2(float(i) * 34.0, float(i % 2) * 8.0)
		_add_rect(parent, "Scooter%sBody" % i, position + offset + Vector2(0.0, 10.0), Vector2(46.0, 10.0), Color(0.06 + float(i) * 0.04, 0.08, 0.11 + float(i) * 0.03, 1.0), 2)
		_add_rect(parent, "Scooter%sSeat" % i, position + offset + Vector2(14.0, 0.0), Vector2(26.0, 9.0), Color(0.018, 0.018, 0.02, 1.0), 3)
		_add_line(parent, "Scooter%sHandle" % i, PackedVector2Array([
			position + offset + Vector2(40.0, 2.0),
			position + offset + Vector2(52.0, -8.0),
		]), 2.0, Color(0.75, 0.75, 0.68, 0.9), 4)
		_add_rect(parent, "Scooter%sWheelA" % i, position + offset + Vector2(4.0, 18.0), Vector2(10.0, 7.0), Color(0.01, 0.012, 0.014, 1.0), 4)
		_add_rect(parent, "Scooter%sWheelB" % i, position + offset + Vector2(34.0, 18.0), Vector2(10.0, 7.0), Color(0.01, 0.012, 0.014, 1.0), 4)


func _add_chai_stall(parent: Node, position: Vector2) -> void:
	_add_rect(parent, "ChaiStall_TinBack", position + Vector2(22.0, 16.0), Vector2(160.0, 76.0), Color(0.08, 0.085, 0.075, 1.0), 0)
	_add_rect(parent, "ChaiStall_Tarpaulin", position, Vector2(204.0, 22.0), Color(0.02, 0.35, 0.27, 1.0), 3)
	_add_rect(parent, "ChaiStall_SaffronBoard", position + Vector2(44.0, 24.0), Vector2(88.0, 16.0), Color(0.86, 0.36, 0.07, 1.0), 2)
	_add_rect(parent, "ChaiStall_YellowBoard", position + Vector2(136.0, 24.0), Vector2(36.0, 16.0), Color(0.95, 0.75, 0.2, 1.0), 2)


func _add_kirana_shutter(parent: Node, position: Vector2) -> void:
	_add_rect(parent, "KiranaShop_Shadow", position + Vector2(0.0, 4.0), Vector2(170.0, 54.0), Color(0.03, 0.032, 0.03, 1.0), 0)
	_add_rect(parent, "KiranaShop_ColorBoardA", position + Vector2(6.0, -18.0), Vector2(84.0, 18.0), Color(0.9, 0.22, 0.1, 1.0), 2)
	_add_rect(parent, "KiranaShop_ColorBoardB", position + Vector2(92.0, -18.0), Vector2(72.0, 18.0), Color(0.95, 0.7, 0.16, 1.0), 2)
	_add_rect(parent, "KiranaShop_HalfShutter", position + Vector2(12.0, 14.0), Vector2(128.0, 34.0), Color(0.14, 0.15, 0.145, 0.96), 1)
	for i in range(5):
		var y := position.y + 20.0 + float(i) * 6.0
		_add_line(parent, "KiranaShop_Slat%s" % i, PackedVector2Array([
			Vector2(position.x + 18.0, y),
			Vector2(position.x + 134.0, y),
		]), 1.0, Color(0.32, 0.32, 0.3, 0.62), 2)


func _add_bmc_bin(parent: Node, position: Vector2) -> void:
	_add_rect(parent, "BMCBin_Body", position, Vector2(58.0, 42.0), Color(0.03, 0.27, 0.12, 1.0), 2)
	_add_rect(parent, "BMCBin_Lid", position + Vector2(-4.0, -7.0), Vector2(66.0, 9.0), Color(0.06, 0.36, 0.16, 1.0), 3)
	_add_rect(parent, "BMCBin_LabelStripe", position + Vector2(10.0, 14.0), Vector2(34.0, 4.0), Color(0.88, 0.9, 0.78, 0.75), 4)


func _add_bus_shelter(parent: Node, position: Vector2) -> void:
	_add_rect(parent, "BESTShelter_Roof", position, Vector2(230.0, 14.0), Color(0.86, 0.18, 0.08, 1.0), 3)
	_add_rect(parent, "BESTShelter_NamePlate", position + Vector2(78.0, -18.0), Vector2(74.0, 18.0), Color(0.95, 0.72, 0.12, 1.0), 4)
	for i in range(4):
		var x := position.x + 16.0 + float(i) * 60.0
		_add_rect(parent, "BESTShelter_Post%s" % i, Vector2(x, position.y + 12.0), Vector2(5.0, 66.0), Color(0.1, 0.13, 0.12, 1.0), 2)
	_add_rect(parent, "BESTShelter_BackGlass", position + Vector2(24.0, 24.0), Vector2(168.0, 38.0), Color(0.08, 0.16, 0.18, 0.36), 1)


func _add_paan_shop_shutter(parent: Node, position: Vector2) -> void:
	_add_rect(parent, "PaanShop_Back", position, Vector2(118.0, 56.0), Color(0.035, 0.03, 0.026, 1.0), 0)
	_add_rect(parent, "PaanShop_GreenBoard", position + Vector2(8.0, -18.0), Vector2(64.0, 18.0), Color(0.08, 0.42, 0.15, 1.0), 2)
	_add_rect(parent, "PaanShop_RedBoard", position + Vector2(74.0, -18.0), Vector2(34.0, 18.0), Color(0.78, 0.08, 0.08, 1.0), 2)
	_add_rect(parent, "PaanShop_Shutter", position + Vector2(12.0, 14.0), Vector2(92.0, 32.0), Color(0.11, 0.12, 0.115, 1.0), 1)


func _add_bamboo_barricade(parent: Node, position: Vector2) -> void:
	_add_rect(parent, "Construction_TinSheet", position + Vector2(6.0, 0.0), Vector2(74.0, 54.0), Color(0.34, 0.34, 0.31, 1.0), 1)
	for i in range(3):
		var x := position.x + float(i) * 28.0
		_add_line(parent, "Construction_Bamboo%s" % i, PackedVector2Array([
			Vector2(x, position.y - 8.0),
			Vector2(x + 22.0, position.y + 58.0),
		]), 4.0, Color(0.68, 0.42, 0.16, 1.0), 3)
	_add_rect(parent, "Construction_StripedBarrier", position + Vector2(-18.0, 38.0), Vector2(138.0, 16.0), Color(0.82, 0.22, 0.06, 1.0), 4)
	for i in range(4):
		_add_rect(parent, "Construction_WhiteStripe%s" % i, position + Vector2(-8.0 + float(i) * 34.0, 38.0), Vector2(14.0, 16.0), Color(0.92, 0.88, 0.72, 1.0), 5)


func _add_zebra_crossing(parent: Node, x_start: float) -> void:
	for i in range(4):
		_add_rect(parent, "FadedZebraStripe%s" % i, Vector2(x_start + float(i) * 26.0, 580.0), Vector2(16.0, 58.0), Color(0.78, 0.78, 0.68, 0.16), 1)


func _add_speed_breaker(parent: Node, x_start: float) -> void:
	_add_rect(parent, "SpeedBreaker_Base", Vector2(x_start, 574.0), Vector2(136.0, 8.0), Color(0.08, 0.075, 0.065, 1.0), 1)
	for i in range(4):
		_add_rect(parent, "SpeedBreaker_YellowStripe%s" % i, Vector2(x_start + 8.0 + float(i) * 32.0, 572.0), Vector2(18.0, 12.0), Color(0.82, 0.64, 0.12, 0.5), 2)


func _place_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and has_node("Spawn"):
		player.global_position = $Spawn.global_position
		player.velocity = Vector2.ZERO


func _spawn_enemies() -> void:
	var enemies := get_node_or_null("Enemies") as Node2D
	if enemies == null:
		enemies = Node2D.new()
		enemies.name = "Enemies"
		add_child(enemies)

	var room_markers := get_node_or_null("RoomMarkers")
	if room_markers == null:
		return

	for room in room_markers.get_children():
		var spawn := room.get_node_or_null("EnemySpawn_1") as Marker2D
		if spawn == null:
			continue

		var enemy := STREET_ENEMY_SCENE.instantiate() as CharacterBody2D
		enemy.name = "Enemy_%s" % room.name
		enemies.add_child(enemy)
		enemy.global_position = spawn.global_position

		var room_data := _room_data_for(room.name)
		enemy.patrol_half_width = float(room_data.get("width", 400.0)) * 0.34


func _room_data_for(room_name: String) -> Dictionary:
	for room in ROOM_DATA:
		if room_name.ends_with("Room%s" % room["id"]) or room_name == "Room%s" % room["id"]:
			return room
	return {"width": 400.0}


func _spawn_attackable_props() -> void:
	var targets := get_node_or_null("AttackableProps") as Node2D
	if targets == null:
		targets = Node2D.new()
		targets.name = "AttackableProps"
		add_child(targets)

	var styles: Array = [
		HurtboxDummyScript.PropStyle.CRATE,
		HurtboxDummyScript.PropStyle.SACK,
		HurtboxDummyScript.PropStyle.CONE,
		HurtboxDummyScript.PropStyle.BIN,
	]
	var style_index := 0

	for marker in _collect_enemy_spawn_markers():
		if str(marker.name) == "EnemySpawn_1":
			continue
		var dummy := HURTBOX_DUMMY_SCENE.instantiate() as StaticBody2D
		dummy.name = "Prop_%s_%s" % [marker.get_parent().name, marker.name]
		dummy.set("prop_style", styles[style_index % styles.size()])
		style_index += 1
		targets.add_child(dummy)
		var spawn_pos := marker.global_position
		if str(marker.name).contains("L2"):
			spawn_pos.y = 464.0
		dummy.global_position = spawn_pos


func _collect_enemy_spawn_markers() -> Array[Marker2D]:
	var markers: Array[Marker2D] = []
	var room_markers := get_node_or_null("RoomMarkers")
	if room_markers == null:
		return markers

	for room in room_markers.get_children():
		for child in room.get_children():
			if child is Marker2D and str(child.name).begins_with("EnemySpawn"):
				markers.append(child)

	markers.sort_custom(func(a: Marker2D, b: Marker2D) -> bool:
		return a.global_position.x < b.global_position.x
	)
	return markers


func _shimmer_windows() -> void:
	for window in get_tree().get_nodes_in_group("lit_windows"):
		if window is ColorRect:
			_animate_window(window)


func _animate_window(window: ColorRect) -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(window, "modulate:a", 0.45, randf_range(2.0, 5.0))
	tween.tween_property(window, "modulate:a", 1.0, randf_range(2.0, 5.0))


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


func _add_polygon(parent: Node, node_name: String, points: PackedVector2Array, color: Color, z: int = 0) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	polygon.z_index = z
	parent.add_child(polygon)
	return polygon
