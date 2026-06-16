# Codex Task: Top-Down Level Design + Visual Redesign v1

Copy the **paste block** at the bottom into a new Codex thread. Godot editor must be open with Godot Catalyst **Connected**.

**Design context:** Builds on the existing `topdown-prototype` branch (combat v0 already works). This task is **level design + visual identity + interactables** — **not** a combat-mechanics rewrite. Keep bite, HP, rival AI, and tuning values unless a layout change forces a tiny spawn tweak.

**Human intent:** Drop side-scrolling visual language entirely. Design from first principles as a **top-down** game inspired by industry standards (Hotline Miami room clarity, Hades hand-crafted arenas, Gungeon environmental interaction, Nuclear Throne readability). Mumbai monsoon night gully / chawl lane — not a generic grey box.

---

## Phase 0 — Mandatory internet research (before any scene edits)

**You must browse the web** and synthesize findings into a short `docs/topdown-v1-research-notes.md` (create this file). Minimum **8 cited bullets** with URLs. Do not skip this phase.

### Research questions (answer all)

| # | Question | Start here |
|---|----------|------------|
| 1 | How does **Hotline Miami** use room size, doorways, and sightlines? | [Steam HL:M Level Design Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3305685660), [Dennaton level editor blog](http://dennaton.blogspot.com/2015/05/hotline-miami-2-level-editor.html) |
| 2 | What is the **door problem** in combat arenas and how do footholds fix it? | [Game Developer — Door Problem of Combat Design](https://www.gamedeveloper.com/design/the-door-problem-of-combat-design) |
| 3 | How should **cover** work in top-down (height vs sight)? | [MY.GAMES top-down shooter level design](https://medium.com/my-games-company/top-down-shooter-level-design-how-map-design-supports-game-mechanics-6ae39fdd095d), [Game Developer — environment layout difficulty](https://www.gamedeveloper.com/design/how-an-environment-layout-affects-difficulty) |
| 4 | What makes **loops and chokepoints** work in action maps? | [World of Level Design — choke points](https://www.worldofleveldesign.com/categories/csgo-tutorials/csgo-principles-choke-point-level-design.php), [CritPoints — loops in FPS](https://critpoints.net/category/level-design/) |
| 5 | How does **Enter the Gungeon** use interactable props? | [Game Developer Q&A — Gungeon](https://www.gamedeveloper.com/design/q-a-the-guns-and-dungeons-of-i-enter-the-gungeon-i-) |
| 6 | How does **Hades** think about room kits (walls, half-cover, traps)? | [Kotaku — Hades level design](https://kotaku.com/hades-level-design-is-less-random-than-it-seems-1845254545), [@EdGorinstein thread summary](https://threadreaderapp.com/thread/1311777010239193088.html) |
| 7 | How should **top-down character sprites** differ from side-view? | [Sandro Maglione — top-down pixel art](https://www.sandromaglione.com/articles/pixel-art-top-down-game-sprite-design-and-animation), [VSQUAD — 2D unit design for camera angle](https://vsquad.art/blog/2d-unit-art-for-games-styles-and-production-process) |
| 8 | What defines **Mumbai monsoon night gully / chawl** spaces? | [Architizer — chawls](https://architizer.com/blog/inspiration/stories/mumbais-chawls-indias-housing-could-soon-disappear/), gully lane community notes |

### Phase 0 deliverable — "feel + layout targets" (5–12 bullets)

Merge research into actionable rules for *this* game, e.g.:

- Room readable in **<2 seconds** (Hotline clarity, not HL:M masks/guns)
- **Internal partitions** over one empty rectangle (door-problem footholds)
- **2–3 tile-wide** choke lanes for a dog-sized character (~32px wide collision)
- **Low cover** = partial sight; **high cover** = full movement block (top-down: solid `StaticBody2D`)
- **Loops** with 2 paths, not one long corridor
- Characters read as **bird's-eye silhouettes**, never side-profile rectangles
- Mumbai identity: sodium amber pools, wet paver sheen, chawl windows, chai stall, BEST stripe, tangled wire hints, puddles

---

## What is wrong today (fix these)

The v0 prototype is functionally fine but **visually and spatially wrong for top-down**:

| Problem | Evidence | Fix direction |
|---------|----------|---------------|
| Characters are **side-profile** dogs | `player_dog_topdown.tscn` — head/snout/ears/legs laid out on +X axis like `dog.tscn` | Rebuild `Visual` as **top-down silhouette** (see spec below) |
| Arena is a **flat open slab** | `arena_mumbai_gully.gd` paints one footpath rect + boundary walls | **Partitioned floor plan** with interior walls, alcoves, chokepoints |
| Dressing is **decorative only** | ColorRects with no gameplay | **Interactable props** with collision +至少 3 behaviors |
| Telegraph is a **horizontal bar above head** | Side-view telegraph habit | **Forward arc/wedge** in bite direction (rival only) |
| No **foothold** at spawn | Player drops into open space | Entry alcove with guaranteed cover before main lane |

**Do not** copy side-view `street_night.tscn` layout or `dog.tscn` node hierarchy for visuals.

---

## Game identity (unchanged from v0)

- Rainy **night Mumbai gully** between chawl wall and shop corrugated lip
- Player: scrappy **stray dog**; enemies: **rival dogs only** (grunt + bully)
- Verbs v0: **8-way move**, **forward lunge bite**, **3 HP**, respawn full HP
- **No** dash, parry, jump, humans, guns, swarm AI in this task

---

## Level design brief — "Gully Three-Pocket" (hand-authored, single screen)

Design a **single 1280×720** combat space that *reads* as three connected pockets — not three separate scenes.

### Floor plan (implement this topology)

Use interior `StaticBody2D` walls (collision layer `world` = 1). Minimum passage width: **56px** (≈1.75× dog width). Target **72–96px** for main lanes.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ CHAWL WALL (top boundary) — windows, drips, sodium light slices              │
├──────────┬─────────────────────────────────────────────┬─────────────────────┤
│ ENTRY    │                                             │ BUS-STOP ALCOVE     │
│ ALCOVE   │              MAIN WET FOOTPATH              │ (BEST stripe, bench)│
│          │         ← primary combat lane →             │                     │
│ [Chai    │    ·····································    │  [Rival B bully]    │
│  stall]  │    ·  puddle   ·   low cover props   ·     │                     │
│          │    ·····································    │                     │
│ [Spawn]  │              ║ choke ║                      │                     │
│          ├──────────────╨───────╨──────────────────────┤                     │
│          │         COURTYARD POCKET (wider)           │                     │
│          │              [Rival A grunt]                 │                     │
│          │    scooter (high cover) · gunny sacks       │                     │
├──────────┴─────────────────────────────────────────────┴─────────────────────┤
│ CORRUGATED SHOP LIP (bottom boundary)                                          │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Spatial design rules (from research — enforce in layout)

1. **Foothold at spawn:** Player spawns behind chai-stall counter (high cover). First rival not in immediate line of sight — must commit through choke.
2. **Chokepoint:** 1 narrow gap (56–72px) between entry alcove and courtyard — forces intentional engagement (Hotline doorway logic).
3. **Loop:** Player can route **main path ↔ bus-stop alcove** around the courtyard partition (partial loop, not a maze).
4. **Cover spacing:** 80–140px between cover islands — exposure gaps for movement (WoLD cover placement).
5. **Sightlines:** From spawn foothold, player sees **part** of main lane, not entire arena (door-problem fix).
6. **Enemy leashing:** Rivals patrol within pocket; grunt in courtyard, bully near bus-stop — pinch if player loops carelessly.

### Palette (document exact `Color()` in research notes)

| Element | Direction |
|---------|-----------|
| Asphalt / gully edge | `#090B0D` – `#13181C` |
| Wet paver footpath | `#272622` – `#2E2C28` |
| Monsoon sheen | amber-tinted specular rects, low alpha |
| Sodium pools | `#F28E42` @ 5–8% alpha cones |
| Chawl plaster | `#1E1F1D` + lit windows `#E69948` @ 65% |
| Chai stall | `#2E1A0B` + amber lip `#F29E47` |
| Puddle | `#172A38` @ 62% |
| BEST stripe | `#0E352E` + amber trim |

---

## Interactable props (minimum 4 types — gameplay, not decals)

Use `Area2D` or `StaticBody2D` + script under `scripts/topdown/props/`. Group: `interactable_prop`. Collision layer **4** (`interactables`) where appropriate.

| Prop | Mumbai identity | Collision | Behavior (v1) |
|------|-----------------|-----------|---------------|
| **Chai stall counter** | Steel top, amber edge, steam puff | High cover — solid | Blocks movement; player bite **clangs** (SFX), brief rival alert radius 120px |
| **Plastic chair** | Classic white/blue stackable | Low cover — solid until kicked | Player bite **kicks** chair 180px in bite dir, slides with friction, becomes low cover 1.5s then settles |
| **Gunny sack stack** | Flour/rice sacks | Low cover | One bite **topples** — sacks scatter as 2–3 small low-cover debris pieces (StaticBody2D), despawn after 8s |
| **Parked scooter** | Generic 100cc silhouette blockout | High cover | Immovable; blocks line of movement; creates flank route around it |
| **BEST bench** | Bus stop alcove | High cover | Solid; optional: bite makes metallic scrape SFX only |
| **Cardboard box** | Street vendor discard | Low — 1 HP | Bite destroys instantly; `GameSfx` thud; no cover after |
| **Tiffin carrier** | Metal dabba | Small solid | Bite → **ring** SFX; pulls nearest rival attention (set aggro true 2s) |

**Implement at least:** chai counter, plastic chair, gunny sacks, scooter (+ 1 destroyable: cardboard box).

**Out of scope v1:** physics explosions, player inventory, persistent prop state across respawn.

### Interactable implementation pattern

```gdscript
# scripts/topdown/props/prop_base.gd
class_name TopdownProp
extends StaticBody2D

@export var prop_kind: StringName
@export var cover_tier: StringName = &"high"  # high | low | none

func on_bite_hit(biter: Node2D, direction: Vector2, damage: int) -> void:
    pass  # override per prop
```

Wire from `player_dog_topdown.gd` attack hitbox: if body is in group `interactable_prop`, call `on_bite_hit`.

---

## Character visual redesign — top-down blockout (ColorRect OK)

**Goal:** Read as a dog **from above** at a glance. 0.5-second silhouette test (VSQUAD rule).

### Anti-patterns (current v0 — do NOT keep)

- Head/snout pointing to permanent +X (side profile)
- Left/right legs on horizontal axis (side stance)
- Ears as vertical flaps on one side of head
- Eye as single pixel on side of face

### Top-down silhouette grammar (both player + rivals)

Build under `Visual` (rotates with `direction.angle()`). Local **+X = forward** (snout direction).

```
                 [earL] [earR]        ← small rects flanking head
               ┌─────────────────┐
               │      head       │     ← wider than snout
               │   [eyes fwd]    │     ← two pixels toward +X, not side
               └────────┬────────┘
                    [snout]            ← small bump at front
          ┌───────────────────────────┐
          │        shoulders          │     ← widest part
          │          body           │
          └───────────────────────────┘
        [LF]              [RF]         ← front paws (toward +X)
        [LB]              [RB]         ← back paws (toward -X)
                  [tail]               ← short rect at -X
        ═══════════════════════        ← elliptical shadow (unchanged idea)
```

**Dimensions (tunable `@export` on a new `scripts/topdown/topdown_visual_spec.gd` or inline):**

| Part | Size (px) | Notes |
|------|-----------|-------|
| Body | 28×18 | Rounded feel via overlapping rects |
| Shoulders | 32×14 | Slightly wider overlay |
| Head | 16×14 | Centered on +X from body |
| Snout | 8×6 | At head +X |
| Ears | 6×5 each | L/R symmetric |
| Paws | 5×5 each | Four corners |
| Tail | 10×4 | -X from body |
| Shadow | 36×10 ellipse via ColorRect | Under everything |

**Player palette:** warm brown stray (`#73522E` body, `#80603A` head).

**Rival grunt:** blue-grey (`#2E2F2D`). **Rival bully:** darker + 10% scale on shoulders.

**Telegraph (rival):** Replace top bar with **forward wedge** ColorRect or Polygon2D in local +X, yellow `#FFC833`, visible during windup only.

**Health bar:** Keep above entity but **narrow** (24×3), not side-view HUD width.

### Collision

- Player body: `CapsuleShape2D` or `RectangleShape2D` **24×20** aligned with rotation
- Attack hitbox: unchanged logic, forward offset in local +X

---

## Architecture — files to create/modify

### Git

```bash
git checkout topdown-prototype
# work on this branch; do not merge to main unless human asks
```

### New / major edits

| Path | Action |
|------|--------|
| `docs/topdown-v1-research-notes.md` | **Create** — Phase 0 web research |
| `docs/topdown-v1-floorplan.md` | **Create** — ascii map + spawn table + cover list |
| `scripts/topdown/arena_mumbai_gully.gd` | **Rewrite** room build → partitioned layout + prop placement |
| `scenes/topdown/arena_mumbai_gully.tscn` | Update if static markers needed |
| `scenes/topdown/player_dog_topdown.tscn` | **Rebuild Visual** top-down |
| `scenes/topdown/rival_dog.tscn` | **Rebuild Visual** top-down + telegraph wedge |
| `scripts/topdown/props/prop_base.gd` | New base class |
| `scripts/topdown/props/prop_*.gd` | Per-prop scripts (≥4) |
| `scenes/topdown/props/*.tscn` | Prop scenes |
| `scripts/topdown/player_dog_topdown.gd` | Minor: forward bite hits `interactable_prop` group |
| `resources/topdown/default_tuning.tres` | Update spawn positions for new layout |

### Do NOT break

- `scenes/main.tscn`, `scenes/player/dog.tscn`, `scenes/levels/street_night.tscn` (side-view)
- `scripts/topdown/topdown_tuning.gd` combat numbers (only add prop/arena exports if needed)
- `GameSfx` autoload pattern
- Physics layers 1=world, 2=player, 3=enemies, 4=interactables
- Camera on player with limits (arena 1280×720)

---

## Implementation phases

### Phase 1 — Research doc
Create `docs/topdown-v1-research-notes.md` with cited bullets. **Stop and summarize** feel targets before coding.

### Phase 2 — Floor plan doc + tuning spawns
Create `docs/topdown-v1-floorplan.md` with final coordinates. Update `spawn_player`, `spawn_rival_a/b` in tuning to match pockets.

### Phase 3 — Character visual rebuild
Rebuild player + rival scenes. F5: dogs must read as top-down when moving in 8 directions. **No side-profile at any rotation.**

### Phase 4 — Partitioned arena
Replace flat `_build_room()` with wall graph + floor zones. Interior walls as `StaticBody2D`. Verify choke width with debug overlay (optional, remove before done).

### Phase 5 — Interactables
Implement ≥4 props, wire bite interaction, place deliberately per floor plan (not random scatter).

### Phase 6 — Polish pass
- Sodium light pools (gradient ColorRects, z behind dressing)
- Wet sheen on main path
- Window drips on chawl wall
- Verify camera limits still correct
- F5 full playtest

---

## Success criteria (human 60s playtest)

1. **No side-view dogs** — silhouette reads top-down while moving N/E/S/W
2. **Arena is not one box** — player must pass a choke to reach courtyard
3. **Spawn foothold works** — chai stall between player and first threat
4. **≥1 interactable moment** — kick chair or topple sacks in fight
5. **Mumbai night** — amber sodium, wet ground, chawl + chai + BEST identifiable
6. **Combat still works** — bite, damage, death respawn, 2 rivals die

---

## Deliverable format (when done)

1. **Research summary** — link to `docs/topdown-v1-research-notes.md`
2. **Floor plan** — link to `docs/topdown-v1-floorplan.md`
3. **Layout rules applied** — 5 bullets mapping research → your geometry
4. **Interactable table** — prop → behavior → scene path
5. **Visual changelog** — player/rival silhouette before vs after
6. **Files touched** — table
7. **F5 test script** — 60s steps for human
8. **Known limitations** — what v2 should add (destructible walls, puddle slow, etc.)

---

## Godot 4 notes

- Interior walls: `StaticBody2D`, layer 1, mask 0; visual child ColorRect
- Props: prefer scene-per-prop for Inspector tuning
- Bite dispatches to props:

  ```gdscript
  if body.is_in_group("interactable_prop") and body.has_method("on_bite_hit"):
      body.on_bite_hit(self, _bite_direction, 1)
  ```

- Use `set_deferred` when toggling monitoring in signal callbacks (existing pattern)
- `GameSfxScript.instance()` for prop sounds

Work **phase by phase**. F5 after phases 3, 4, 5, 6.

---

## Paste block (for Codex)

```
You are working on Street Dog — Godot 4.6 2D at:
/Users/aman.shrivastava/Documents/personal/projects/street-dog-draft

Read AGENTS.md and the FULL task spec:
docs/codex-topdown-v1-level-design-prompt.md

Godot editor open · Godot Catalyst MCP Connected (port 6505).

PHASE 0 IS MANDATORY: Use the internet to research top-down combat level design
(Hotline Miami room clarity, door-problem footholds, cover/choke/loops, Gungeon
interactables, Hades room kits, top-down sprite principles, Mumbai gully/chawl
aesthetics). Write docs/topdown-v1-research-notes.md with ≥8 cited bullets BEFORE
any scene edits.

Then implement v1 on branch topdown-prototype:
- REDESIGN player + rival visuals as authentic top-down silhouettes (NOT side-profile)
- REBUILD arena as partitioned "Gully Three-Pocket" floor plan (1280×720)
- ADD ≥4 Mumbai-themed interactable props with bite behaviors
- KEEP existing combat mechanics (move, bite, HP, rival AI) — layout/spawn tweaks only
- DO NOT break side-view scenes (main.tscn, dog.tscn, street_night.tscn)

Follow phases 1→6 in the doc. F5 after each major phase. Fix all errors before continuing.
When done, output the deliverable format from the doc.
```
