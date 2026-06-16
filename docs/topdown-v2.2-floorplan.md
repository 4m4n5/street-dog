# Topdown v2.2 Floorplan - Monsoon Gully Network

Date: 2026-06-16  
Scope: layout and set dressing only. v2.1 combat, archetypes, prop verbs, and room clear are preserved.

## Lane Graph

```text
  north chawl/loggia facade, windows, wire tangles, stairs
  ################################################################
  # WEST SHOP BLOCK       main gully       NORTH CHAWL     EAST CHAWL
  #                       wet run          footprint       bus back
  #                    +-------------+
  #                    | gully fork  |------ wadi / chowk ------ BEST chowk
  #                    | sentry      |       stray + scooter     bully + bench
  #                    +------+------+              |              |
  #                           |                     |              |
  # nukkad / chai foothold ---+---------------- by-lane ----------+
  # spawn, chai counter                         racer, laundry
  ################################################################
  south corrugated shop lip / wet vendor spill
```

Node order: `nukkad -> main gully -> gully fork -> wadi/chowk -> BEST chowk`, with a second route through `by-lane -> BEST chowk`.

## Building Footprints

| Footprint | Rect | Facade role | Layout job |
|---|---:|---|---|
| `BoundaryTop_ChawlSkyline` | `(0,0) 1280x88` | north chawl band | open-sky top edge, windows/loggia |
| `BoundaryBottom_CorrugatedShopEdge` | `(0,628) 1280x92` | south shop lip | bottom facade, no void gutters |
| `BoundaryLeft_Shopbacks` | `(0,0) 32x720` | west backs | arena edge |
| `BoundaryRight_BusDepotEdge` | `(1248,0) 32x720` | east depot | arena edge |
| `Footprint_WestShopBlock_ChaiShoulder` | `(32,88) 238x356` | chai-side shop mass | hides nukkad from fork/wadi |
| `Footprint_NorthChawl_LongFacade` | `(470,88) 338x192` | chawl block | carves fork/wadi south edge |
| `Footprint_EastChawl_BusBack` | `(1014,88) 234x142` | bus-stop back wall | frames BEST chowk |
| `Footprint_ForkCornerClinic` | `(500,432) 92x108` | small corner shop | blocks spawn LOS through fork |
| `Footprint_WadiSouthWorkshop` | `(438,540) 208x88` | workshop shoulder | splits main gully from by-lane |
| `Footprint_BESTDepotKiosk` | `(1128,474) 120x154` | bus depot kiosk | gives bully pocket a hard curb |

## Lane Segments

| Segment | Rect | Width tier | Wet/dry | Choke role |
|---|---:|---:|---|---|
| `Node_NukkadChaiFoothold` | `(44,448) 228x180` | pocket 180px | wet pavers | safe spawn foothold |
| `Lane_MainGullyWetRun` | `(270,408) 206x220` | main 96-140px usable | wet | commit lane out of chai |
| `Node_GullyFork` | `(418,292) 204x248` | fork 72-120px | wet | sentry leash node |
| `Node_WadiChowk` | `(604,300) 304x224` | chowk 120-200px | wet | first stray pocket |
| `Lane_ByLaneLaundryCut` | `(646,540) 368x88` | by-lane 56-88px | damp | racer side route |
| `Lane_WadiToBestMouth` | `(872,360) 96x128` | main 72-96px | wet | BEST connector |
| `Node_BESTChowkBusStrip` | `(944,244) 284x236` | chowk 120-200px | wet curb | bully pressure pocket |

## Spawn And Rivals

| Marker | Position | Role | Notes |
|---|---:|---|---|
| `Spawn` | `(148,532)` | player | unchanged tuning spawn inside chai nukkad |
| `RivalSpawn_Stray` | `(704,404)` | wadi patrol | first visible fight after fork commit |
| `RivalSpawn_Sentry` | `(558,334)` | fork leash | owns junction, outside main-mouth detection |
| `RivalSpawn_Racer` | `(846,586)` | by-lane skirmish | reached through laundry lane |
| `RivalSpawn_Bully` | `(1092,348)` | BEST chowk pressure | readable on green bus stripe |
| `RivalSpawn_A` | `(704,404)` | legacy alias | aligned to Stray |
| `RivalSpawn_B` | `(1092,348)` | legacy alias | aligned to Bully |

## Props And Set Dressing

| Prop | Position | Lane-relative placement |
|---|---:|---|
| `ChaiStallCounter_Nukkad` | `(158,496)` | spawn foothold cover and chai identity |
| `PlasticChair_MainGullyMouth` | `(354,458)` | main gully cover/kick line |
| `GunnySacks_ForkShoulder` | `(456,372)` | low cover before sentry fork |
| `ParkedScooter_WadiEdge` | `(760,448)` | high cover in wadi |
| `BESTBench_ChowkStrip` | `(1102,292)` | bus-stop cover beside bully |
| `CardboardBox_BESTCurb` | `(1018,430)` | destroyable clutter on BEST connector |
| `CardboardBox_ByLaneRear` | `(880,586)` | racer lane clutter |
| `LaundryLinePoles_ByLaneMouth` | `(710,548)` | spans by-lane mouth |

Set dressing added in builder: `ChawlLoggiaStair_*`, `WadiRingStep_*`, `WireTangle_NukkadToFork`, `WireTangle_WadiLaundry`, `WireTangle_BESTChowk`, and three `WireDrip_*` lines.

## LOS Audit

| From spawn `(148,532)` | Target | Requirement | Audit |
|---|---|---|---|
| Player | Stray `(704,404)` | blocked until lane commit | blocked by `Footprint_ForkCornerClinic` and wadi corner |
| Player | Sentry `(558,334)` | blocked at nukkad | blocked by chai counter plus west shop / clinic corner |
| Player | Racer `(846,586)` | blocked at nukkad | lower by-lane hidden by `Footprint_WadiSouthWorkshop` |
| Player | Bully `(1092,348)` | blocked at nukkad | blocked by fork clinic and BEST connector turn |
| Player | Fork landmark | partial | sodium lane mouth and gunny sacks visible |
| Player | Main gully depth | partial | single corner peek; no straight shot to chowk |

## Anti-Pattern Checklist

| Check | Status |
|---|---|
| No `SpawnPartition_*` walls | PASS |
| No `ForkDivider_*` walls | PASS |
| No `BusPartition_*` walls | PASS |
| No `LoopIsland_*` interior wall | PASS |
| Building mass carves walkable negative space | PASS |
| At least four facade footprints touch lane edges | PASS |
| At least one visible T/Y fork | PASS |
| At least two outdoor routes to late pockets | PASS |
| Hidden nukkad spawn is documented | PASS |
| Side-view scenes untouched by this layout spec | PASS |

## 60s F5 Script

1. Hold at nukkad for 5s: chai counter, shop shoulder, and lane-mouth sodium read before rivals.
2. Move east/north into main gully: first combat read is wadi/stray, not a door or partition room.
3. Step into fork: sentry holds the junction and does not start in spawn band.
4. Drop south/east through by-lane: laundry poles and racer mark the alternate route.
5. Push to BEST chowk: bully is staged on the green bus stripe with bench cover.
6. Kill all rivals: `gully clear` still appears and rivals respawn from role markers.
