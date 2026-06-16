# Top-Down v1 Floor Plan: Gully Three-Pocket

Single-screen combat arena: 1280x720. Coordinates are in Godot pixels from top-left.

## ASCII Map

```text
0,0                                                                         1280,0
+----------------------------------------------------------------------------+
| CHAWL WALL / lit windows / drips                                            |
+------ entry alcove -----+---------------- main wet footpath -----+-- BEST --+
|                         |                                        | alcove   |
| chai clutter            |     puddles + low cover islands        | bench    |
|                         |                                        |          |
|                         |                 loop opening           | bully    |
|          CHAI           |         +------------------+           |          |
|         COUNTER         |         | courtyard wall   |           |          |
| spawn                   | choke   +-------- 92px ----+           |          |
|                         | 72px       COURTYARD POCKET            |          |
|                         |          grunt / scooter / sacks       | boxes    |
+-------------------------+----------------------------------------+----------+
| CORRUGATED SHOP LIP / wet shutter edge                                      |
+----------------------------------------------------------------------------+
0,720                                                                       1280,720
```

## Pocket Rects

| Pocket | Rect2 top-left/size | Purpose |
|---|---:|---|
| Entry alcove | `(32, 112) size (238, 512)` | Spawn foothold, chai stall, first commitment route |
| Main wet footpath | `(302, 112) size (678, 250)` | Primary readable east-west lane |
| Courtyard pocket | `(302, 362) size (678, 262)` | Wider brawl space with low/high cover islands |
| Bus-stop alcove | `(1012, 112) size (236, 512)` | Late pressure pocket and loop reward/risk |

## Spawn Table

| Actor | Position | Facing/Intent |
|---|---:|---|
| Player | `Vector2(150, 536)` | Starts below/behind chai counter in entry alcove |
| Rival A grunt | `Vector2(600, 472)` | Courtyard patrol, first committed fight |
| Rival B bully | `Vector2(1110, 296)` | Bus-stop pocket patrol, punishes careless loop |

## Collision Walls

| Wall | Rect2 top-left/size | Notes |
|---|---:|---|
| Boundary top/chawl | `(0, 0) size (1280, 96)` | Full high wall |
| Boundary bottom/shop lip | `(0, 624) size (1280, 96)` | Full high wall |
| Boundary left | `(0, 0) size (32, 720)` | Full high wall |
| Boundary right | `(1248, 0) size (32, 720)` | Full high wall |
| Entry partition north | `(270, 96) size (32, 344)` | Blocks spawn sightline into main lane |
| Entry partition south | `(270, 512) size (32, 112)` | Leaves one 72px entry choke |
| Courtyard divider west | `(390, 346) size (300, 32)` | Separates main from courtyard |
| Courtyard divider east | `(782, 346) size (198, 32)` | Leaves a 92px loop opening |
| Bus partition north | `(980, 96) size (32, 150)` | Frames bus-stop upper entrance |
| Bus partition south | `(980, 512) size (32, 112)` | Frames bus-stop lower exit |

## Cover And Props

| Prop/Cover | Position | Tier | Gameplay job |
|---|---:|---|---|
| Chai stall counter | center `Vector2(154, 486)` | High | Spawn foothold, bite clang, local alert |
| Plastic chair | center `Vector2(418, 292)` | Low | Kickable into main-lane exposure gap |
| Gunny sack stack | center `Vector2(692, 520)` | Low | Topples into temporary debris |
| Parked scooter | center `Vector2(506, 536)` | High | Courtyard flank blocker |
| BEST bench | center `Vector2(1108, 164)` | High | Bus-stop anchor, scrape on bite |
| Cardboard box A | center `Vector2(1154, 452)` | Low/1 HP | Breakable vendor discard |
| Cardboard box B | center `Vector2(1036, 562)` | Low/1 HP | Breakable lower-loop clutter |

## Applied Layout Rules

- Player cannot see both rivals from spawn; entry partition plus chai counter create hidden information.
- Entry-to-courtyard commitment is one 72px choke, above the 56px minimum and narrow enough to read as a doorway problem fix.
- Courtyard divider creates a pocket instead of one slab, while the 92px right opening keeps the loop navigable.
- High cover blocks movement/sight; low cover props sit 80-140px apart to force short exposed moves.
- Rival A starts outside immediate detection range from spawn; Rival B is farther and only becomes pressure when the player uses the loop.
