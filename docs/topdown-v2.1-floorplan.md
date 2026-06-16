# Topdown v2.1 Floorplan - Chawl Fork

Scene target: `res://scenes/topdown/main_topdown.tscn`
Arena script: `res://scripts/topdown/arena_mumbai_gully.gd`
Canvas: 1280 x 720

## ASCII Thumbnail

```text
0,0                                                                    1280,0
┌──────────────────────────────────────────────────────────────────────────┐
│ CHAWL LOGGIA: wet plaster, windows, laundry-line poles, overhead wires    │
├───────────────┬────────────── MAIN WET LANE ────────────┬───────────────┤
│ SPAWN         │      chairs / puddle / amber light       │ BEST ALCOVE   │
│ FOOTHOLD      │                                          │ bench + boxes │
│ chai high     ├── narrow choke ── FORK T-JUNCTION ───────┤ sentry leash  │
│ cover + boxes │                     │                    │ bully pressure│
│               │                 COURTYARD WELL           │               │
│               │              scooter + sacks + puddle     │               │
│               └──── wider rear choke ─── side loop ──────┴── racer lane ┤
│ CORRUGATED SHOP LIP: vendor spill, sacks, wet curb, sodium edge           │
└──────────────────────────────────────────────────────────────────────────┘
0,720                                                                  1280,720
```

## Pocket Rects

| Pocket | Rect | Design purpose |
|--------|------|----------------|
| Spawn foothold | `(32, 112) -> (286, 624)` | Safe first read behind chai high cover; cannot see all rivals |
| Main wet lane | `(314, 112) -> (832, 338)` | First exposure lane with low chair cover and sodium/puddle readability |
| Fork T-junction | `(532, 250) -> (760, 444)` | Central decision point; sentry leash owns the narrow commit |
| Courtyard well | `(318, 384) -> (840, 624)` | Wider brawl pocket for Stray, scooter, sacks, and lower loop access |
| BEST alcove | `(980, 112) -> (1248, 500)` | Bully pressure pocket with bench and boxes |
| Side loop lane | `(812, 506) -> (1248, 624)` | Racer skirmish lane; wider rear choke gives flank route |
| Chawl loggia | `(36, 20) -> (1244, 92)` | Mumbai identity band; laundry poles and window grid |
| Corrugated shop lip | `(32, 624) -> (1248, 696)` | Bottom identity band and hard boundary |

## Wall Table

| Node | Position | Size | Notes |
|------|----------|------|-------|
| BoundaryTop_ChawlWall | `(0, 0)` | `(1280, 96)` | high wall |
| BoundaryBottom_CorrugatedLip | `(0, 624)` | `(1280, 96)` | high wall |
| BoundaryLeft_NarrowGully | `(0, 0)` | `(32, 720)` | high wall |
| BoundaryRight_NarrowGully | `(1248, 0)` | `(32, 720)` | high wall |
| SpawnPartition_North | `(286, 96)` | `(28, 286)` | leaves 62px narrow choke at `y=382..444` |
| SpawnPartition_South | `(286, 444)` | `(28, 180)` | keeps spawn foothold separate |
| ForkDivider_Upper | `(532, 338)` | `(228, 28)` | T stem, blocks full-lane LOS |
| ForkDivider_Lower | `(760, 366)` | `(28, 146)` | creates rear choke approach |
| BusPartition_North | `(952, 96)` | `(28, 188)` | hides bully/sentry from spawn |
| BusPartition_South | `(952, 500)` | `(28, 124)` | leaves lower loop to bus |
| LoopIsland_ScooterWall | `(610, 488)` | `(156, 28)` | island cover near courtyard/loop |

## Chokes

| Choke | Range | Width | Purpose |
|-------|-------|-------|---------|
| Spawn commit choke | `x=286..314, y=382..444` | 62 px | first bite-commit threshold; Sentry leash watches but cannot chase into spawn |
| Rear loop choke | `x=760..812, y=512..604` | 92 px | wider flank/escape route from courtyard to racer lane |
| Bus mouth | `x=952..980, y=284..500` | 216 px | bigger pressure mouth; not a formal choke |

## Spawn Table

| Marker | Position | Pocket | Behavior |
|--------|----------|--------|----------|
| Spawn | `(148, 532)` | Spawn foothold | player starts behind chai cover |
| RivalSpawn_Stray | `(592, 486)` | Courtyard well | patrol/teaching rival |
| RivalSpawn_Sentry | `(704, 286)` | Fork/main choke | short leash, fair long telegraph |
| RivalSpawn_Racer | `(1084, 562)` | Side loop lane | skirmish/flank pressure |
| RivalSpawn_Bully | `(1118, 306)` | BEST alcove | heavy pressure, long recovery |
| RivalSpawn_A | `(592, 486)` | legacy alias | deprecated; maps to Stray for one release |
| RivalSpawn_B | `(1118, 306)` | legacy alias | deprecated; maps to Bully for one release |

## Prop Table

| Prop | Position | Cover | Behavior |
|------|----------|-------|----------|
| ChaiStallCounter | `(154, 482)` | high | spawn foothold; bite alerts nearby rivals |
| PlasticChair_MainLane | `(438, 278)` | low | kicks forward; sliding contact staggers rival |
| GunnySacks_Courtyard | `(700, 544)` | low | bite topples into debris |
| ParkedScooter_Courtyard | `(526, 548)` | high | courtyard island cover |
| BESTBench_BusStop | `(1102, 174)` | high | bus alcove anchor |
| CardboardBox_BusStop | `(1166, 444)` | low | bite breaks |
| CardboardBox_LowerLoop | `(996, 572)` | low | loop obstruction; bite breaks |
| LaundryLinePoles_Loggia | `(832, 90)` | high | two poles with decorative line; blocks movement at top lane |

## Playtest Script

1. Spawn at foothold and confirm chai counter hides direct sight to bus/racer pockets.
2. Move through the 62px spawn choke; Sentry should wind up but not retreat into spawn.
3. Circle down into courtyard; Stray should patrol/chase and lunge with wedge telegraph.
4. Enter lower loop; Racer should pressure laterally with shorter startup.
5. Push bus alcove; Bully should lunge with heavy knockback and long recovery.
6. Kick chair into a rival; it should stagger briefly and cause no HP damage.
7. Kill all four rivals; `gully clear` appears, then all four respawn after the clear beat.
