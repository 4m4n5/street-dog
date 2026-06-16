# Topdown v3 Light Street Floorplan

Segment: `street_segment_gully_01`
World bounds: `Rect2(Vector2.ZERO, Vector2(1920, 1080))`
Viewport target: 1280x720, player `Camera2D` clamped to segment bounds.

## Light Graph

```text
 y=0
  [north chawl dark mass + occluders]
  x=0                                                        x=1920
  |###############################################################|
  |### chai spill ###     LAMP_A                 LAMP_B    ######|
  |### player spawn  ###    (first pool)           (fork)  #dark#|
  |#                    ===== wet main run =======          gully#|
  |# west dark mouth -->  Stray      Sentry   Racer/Bully <-spawn#|
  |#                         \__ side gully choke __/       ######|
  |###############################################################|
  [south corrugated lip + shop backs]
 y=1080
```

## Coordinates

| Element | Position / rect | Notes |
| --- | --- | --- |
| Segment size | `1920 x 1080` | Authoritative bounds for camera and collision. |
| Player spawn | `Vector2(190, 650)` | Inside chai spill foothold, west of first pole. |
| `SPILL_CHAI` | `Vector2(220, 610)`, wash `240 x 150` | Painted decal only; no shadows. |
| `LAMP_A` | `Vector2(640, 500)` | Radius 175, energy 1.55; first combat pool. |
| `LAMP_B` | `Vector2(1285, 470)` | Radius 185, energy 1.62; fork pressure pool. |
| Main wet run | `Rect2(120, 390, 1620, 275)` plus diagonal shoulders | Continuous pavement spine. |
| Side gully mouth | `Rect2(830, 650, 120, 116)` | ~64px choke at entry, dark. |
| East dark gully | `Rect2(1500, 545, 220, 210)` | Racer/Bully spawn shoulder. |
| North dark cut | `Rect2(1010, 292, 140, 128)` | Sentry spawn behind fork. |

## Blocking And Occlusion

| Facade | Rect / polygon | Responsibility |
| --- | --- | --- |
| North shoulder | `Rect2(0, 0, 1920, 260)` with cutouts | World collision, dark mass, light occlusion. |
| South shoulder | `Rect2(0, 790, 1920, 290)` with side-gully cut | World collision, corrugated lip, light occlusion. |
| West backs | `Rect2(0, 0, 96, 1080)` | Keeps spawn edge framed. |
| East backs | `Rect2(1818, 0, 102, 1080)` | Prevents void and frames east gully. |
| Side-gully block | L-shaped facades around `x=760..1140, y=665..850` | Creates dark side cut without rooms. |

## Props

| Prop | Position | Cover tier / verb | Placement reason |
| --- | --- | --- | --- |
| Chai counter | `Vector2(230, 610)` | High / bite thud | Foothold edge inside warm spill. |
| Plastic chair | `Vector2(590, 540)` | Low / kick + stagger | Readable in `LAMP_A` pool. |
| Gunny sacks | `Vector2(890, 640)` | Low / topple | Side-gully mouth affordance. |
| Parked scooter | `Vector2(1340, 560)` | High / bite thud | Edge cover in `LAMP_B` pool. |
| Cardboard box | `Vector2(1495, 635)` | Low / destroy | East shoulder clutter in light falloff. |

## Single-Wave Spawn And Emerge

| Archetype | Dark spawn | Emerge target | Role |
| --- | --- | --- | --- |
| Stray | `Vector2(430, 710)` west dark mouth | `Vector2(585, 525)` | Teaching patrol in `LAMP_A`. |
| Sentry | `Vector2(1050, 340)` north cut | `Vector2(1005, 500)` | Leash at side-gully choke. |
| Racer | `Vector2(1610, 655)` east shoulder | `Vector2(1325, 525)` | Flank through `LAMP_B`. |
| Bully | `Vector2(1690, 575)` deep east gully | `Vector2(1395, 500)` | Pressure in `LAMP_B`. |

## LOS Notes

- Player spawn cannot see all rivals at load because rivals start in dark cuts behind facade shoulders.
- `LAMP_A` is visible from spawn and becomes the first forward cue.
- `LAMP_B` is partially visible but requires camera scroll to inspect fully.
- Side-gully mouth is narrow enough to read as a choke but not as a room doorway.
- Props sit at pool edges so their silhouettes remain readable under sodium falloff.

## 60s F5 Script

1. Spawn at chai spill; confirm dark base, warm spill, and first amber pool are readable.
2. Move east to `LAMP_A`; confirm camera scroll begins before `LAMP_B`.
3. Watch all four rivals emerge from dark markers into their assigned pools.
4. Bite chair/sacks/scooter; confirm existing prop verbs still respond.
5. Kill all four rivals; confirm lowercase `gully clear` appears.
6. Wait for respawn; confirm the same single wave returns from dark spawns.
7. Walk to each segment edge; confirm no void appears outside camera bounds.
