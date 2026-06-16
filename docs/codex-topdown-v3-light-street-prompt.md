# Codex Task: Top-Down v3 — Light-First Mumbai Street Segment

**Project:** Street Dog · **Engine:** Godot 4.6 · **Renderer:** GL Compatibility · **Branch:** `topdown-prototype`

**Invoke skill:** `$topdown-combat-expert` — read `SKILL.md` + `knowledge-base.md` before implementation.

**Design authority:** `docs/topdown-v3-light-street-design-brief.md`
**Visual references:** `references/level1/ref{1-4}.jpeg` (light pools, arterial + alley grammar)

**Godot Catalyst MCP must be Connected.** Do not invent node paths.

**Do not ask the human questions.** All scope decisions are locked below.

---

## Executive summary

Ship a **vertical slice** of the new top-down level design direction: a **small,
scrollable Mumbai street segment at night** where **authored lighting** — not
partition walls — defines navigation, mood, and combat readability.

This replaces the v2.x “combat arena” approach (`arena_mumbai_gully.gd` topology).
Combat systems from v2.1 remain; **level geometry and lighting are net-new.**

---

## Locked human decisions (final)

| Parameter | Value |
|-----------|--------|
| **Encounter structure** | **Single wave** — all 4 rivals in one encounter; no multi-zone wave progression in v3.0 |
| **Segment size** | **Small** — ~**1920 × 1080** world units (modest scroll beyond 1280×720 viewport) |
| **Lamp count (v3.0)** | **2 sodium street poles** + **1 chai shop spill** (no BEST / fairy / window grid yet) |
| **Layout grammar** | Hybrid — arterial lamp rhythm (ref3/ref4) + one irregular dark side gully (ref1/ref2) |
| **Movement** | 8-way, `MOTION_MODE_FLOATING`, player-follow `Camera2D` |
| **Light gameplay** | **Readability + mood only** — no stealth aggro, no light-meter mechanics |
| **Light technology** | **Hybrid** — `CanvasModulate` night base + `PointLight2D` on poles + painted chai spill decal |
| **Rival presentation** | Spawn in **dark alley** off-pool → **emerge** into nearest lamp pool at wave start |
| **Encounter end** | Preserve soft room clear: `gully clear` → respawn **same single wave** (reshuffle alley spawns optional, not required) |
| **Implementation** | **New scene graph**; preserve combat scripts; do **not** extend v2.2 partition builder |
| **Side-view branch** | Untouched (`main.tscn`, `street_night.tscn`, etc.) |

---

## Design intent

### Player fantasy

You are a street dog moving through a **real Mumbai gully at night** — sodium
pools on wet pavement, chai glow at the corner, darkness between buildings.
Fights happen **under the lamps**, not inside abstract rooms.

### Art direction pillars (non-negotiable)

1. **Light leads layout** — pole positions and pool radii are placed before collision geometry ([Level Design Book — lighting](https://book.leveldesignbook.com/process/lighting)).
2. **High contrast** — motivated dark base; pools are the primary navigation signal (ref4).
3. **Street, not arena** — continuous pavement; building mass on edges; no interior `Partition_*` walls.
4. **Mumbai, not cyberpunk** — amber sodium `#F28E42`, wet charcoal pavement, warm chai spill — not neon magenta/cyan.

### What we are explicitly abandoning

- v2.1/v2.2 `ColorRect` zone painting as the primary layout language
- Single-screen 1280×720 playpen with facade partitions
- Flat alpha “sodium slices” without `Light2D` falloff
- Layout-first, light-last workflow

---

## Reference translation (for level artists / designers)

| Reference | Extract for v3.0 | Do not copy |
|-----------|------------------|-------------|
| ref4 | Circular amber lamp pools on dark asphalt; intersection choke | Modern highway scale |
| ref3 | Dark building shoulders flanking lit arterial | Satellite realism |
| ref1/2 | Irregular side cut, shop spill into dark lane | Cyberpunk signage palette |
| Prior v2.2 floorplan | Rival **roles** only (Stray/Sentry/Racer/Bully) | Wall graph, coords, partition names |

---

## World specification — “Gully Segment 01”

### Bounds

| Property | Target |
|----------|--------|
| World size | **1920 × 1080** px (authoritative; export on segment root) |
| Viewport | 1280 × 720 (unchanged) |
| Scroll feel | ~1.5 screens longest axis — player discovers second lamp by moving forward |
| Camera | Player `Camera2D` follow; limits clamped to segment bounds (no void gutters) |

### Light graph (place before collision)

```text
                    [north chawl shoulder — dark mass + occluders]
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
  ░░ chai spill ░░   ● pole A          ● pole B        ░░ dark ░░
  ░░  (warm)     ════════ wet main run ═══════════════   ░ gully ░░
  ░░  spawn      ╲                              ╱       ░░     ░░░
  ░░░░░░░░░░░░░░░░╲____ side gully (dark) ____╱░░░░░░░░░░░░░░░░░
                    [south corrugated lip — dark mass]
```

### Authored lights (v3.0)

| ID | Type | Position (designer-tuned) | Pool radius | Purpose |
|----|------|---------------------------|------------|---------|
| `LAMP_A` | Sodium `PointLight2D` | ~main run, west-center | ~140–180 px | First combat pool; Stray emerges here |
| `LAMP_B` | Sodium `PointLight2D` | ~main run, east-center | ~140–180 px | Fork pressure; Sentry + Bully emerge |
| `SPILL_CHAI` | Painted decal (no shadow) | Nukkad / spawn lip | ~120 px wash | Player foothold; warm `#F29E47` |

**Performance budget:** ≤3 `PointLight2D` nodes active in v3.0.

### Collision / topology

- **Walkable:** single continuous wet paver surface on main run + chai nukkad + optional short side gully stub (~56–72 px wide).
- **Blocking:** north/south/east/west segment bounds + **facade occluders** along building shoulders (not room partitions).
- **Cover:** reposition existing props (chair, sacks, scooter) **inside or at edge of lamp pools** — minimum 2 props with verbs (chair kick, sacks).
- **Choke:** narrow mouth where side gully meets main run (~64 px) — optional Sentry leash anchor.

### Single-wave encounter table

All rivals active in **one wave** at level load. Spawn in darkness; **emerge** into assigned pool over ~0.4–0.8s (tween or patrol-to-point).

| Archetype | Dark spawn (alley) | Emerge target | AI role |
|-----------|-------------------|---------------|---------|
| **Stray** | West side gully | `LAMP_A` pool | Teaching patrol |
| **Sentry** | North cut behind fork | Between A/B pools | Leash at choke |
| **Racer** | East dark shoulder | `LAMP_B` pool (flank) | Skirmish |
| **Bully** | Deep east gully | `LAMP_B` pool | Pressure |

**Emerge behavior:** On `_ready` or wave start, rivals path to emerge point before normal AI. Silhouette must be readable in pool (contrast against wet ground).

**No zone gating** in v3.0 — do not require clearing pool A before B activates.

---

## Technical requirements

### New scenes / scripts (expected)

| Asset | Responsibility |
|-------|----------------|
| `scenes/topdown/levels/street_segment_gully_01.tscn` | Root segment: bounds, layers, lamps, props, spawns |
| `scripts/topdown/levels/street_segment.gd` | Segment bounds, camera limit export, rival spawn API |
| `scenes/topdown/props/street_lamp_topdown.tscn` | Top-down sodium pole + `PointLight2D` + optional pool decal |
| `scripts/topdown/props/street_lamp_topdown.gd` | Radial gradient texture, amber energy, shadow config |
| `scripts/topdown/levels/street_wave_controller.gd` | Single-wave emerge sequencing + hooks `arena_encounter` respawn |
| `docs/topdown-v3-light-street-floorplan.md` | Light graph, bounds, lamp coords, spawn/emerge table, LOS notes |

**Reuse/adapt:** Side-view `scenes/props/street_lamp.tscn` logic is a reference for gradient texture — **fork for top-down** (fixture reads from above, not side-profile pole).

### Lighting pipeline (Godot 4)

1. **`CanvasModulate`** on segment (or main) — night base `Color(0.45, 0.48, 0.55)` or darker per playtest.
2. **`PointLight2D`** per pole — `shadow_enabled = true`, `blend_mode` appropriate for GL Compatibility.
3. **`LightOccluder2D`** on building shoulder polygons — block light bleed through facades.
4. **Chai spill** — `Sprite2D`/`ColorRect` gradient decal, high z-index, **not** a light node.
5. **Characters** — verify player + rivals render correctly in lit environment (may need `canvas_item` material defaults; document if changed).

**Citation:** [Catlike Coding — True Top-Down 2D lighting](https://catlikecoding.com/godot/true-top-down-2d/4-light-and-shadow/)

### Camera integration

Player `Camera2D` currently clamps to `tuning.arena_width/height`. **Wire segment bounds** instead:

- Add `@export var segment_size: Vector2` on `street_segment.gd` (default `1920, 1080`).
- On load, segment calls player method or sets group metadata so camera limits match segment — **not** legacy 1280×720 arena tuning.

### Preserve without regression

| System | Path |
|--------|------|
| Player bite v2 | `player_dog_topdown.gd`, `default_tuning.tres` preset B |
| Rival bite FSM | `rival_dog.gd`, `bite_attack_profile.gd` |
| Archetypes | `resources/topdown/archetypes/*.tres` |
| Room clear | `arena_encounter.gd` — adapt `arena_path` / respawn target to new segment |
| Prop verbs | `scripts/topdown/props/*` |
| Physics layers | 1 world, 2 player, 3 enemies, 4 interactables |
| HUD | `player_hud_topdown.tscn` |

### Do NOT modify

- `player_dog_topdown.gd` attack FSM / buffer / juice (unless ≤10 lines for camera limit hook)
- `rival_dog.gd` bite math
- Side-view scenes and scripts

### Entry scene

Update `scenes/topdown/main_topdown.tscn` to instance **`street_segment_gully_01`** instead of `arena_mumbai_gully`. Keep `ArenaMumbaiGully` scene file in repo (inert) or move to `_deprecated/` — do not delete without note in deliverable.

---

## Phase plan

| Phase | Deliverable | Gate |
|-------|-------------|------|
| **0** | `docs/topdown-v3-light-street-research-notes.md` — ≥8 cited bullets (lighting + Mumbai + Godot Light2D) | — |
| **1** | `docs/topdown-v3-light-street-floorplan.md` — light graph, coords, emerge table | Human-readable |
| **2** | `street_lamp_topdown` scene + night `CanvasModulate` — **lamps only on greybox plane** | F5: visible pools |
| **3** | Full segment collision + facades + occluders + 2 poles + chai spill | F5: street read |
| **4** | Props + single-wave emerge + 4 rivals | F5: fight under lamps |
| **5** | Wire `main_topdown`, encounter respawn, camera bounds | F5: full loop |
| **6** | Git commits (logical chunks); never push unless asked | `git log` |

---

## Acceptance criteria (QA / playtest)

1. **Night read (5s):** Player identifies **lit path** vs **dark shoulders** before identifying walls.
2. **Segment scale:** Moving from chai spawn to second lamp requires **camera scroll** — segment feels larger than one screen.
3. **Lamp pools:** Two distinct amber pools with visible falloff; darkness between poles.
4. **Chai spill:** Warm wash at spawn; readable separately from sodium.
5. **Street vocabulary:** Space reads as gully/main run/side cut — not “rooms” or “partitions.”
6. **Emerge:** All 4 rivals enter from dark areas into lamp pools; silhouettes readable in pool.
7. **Combat parity:** Player bite buffer/juice unchanged; rival telegraphs unchanged.
8. **Room clear:** Kill all 4 → lowercase `gully clear` → respawn → second run works.
9. **Camera:** No void outside segment bounds at any scroll position.
10. **Side-view:** `main.tscn` still loads (smoke test only).

---

## Out of scope (v3.0)

- Multi-zone wave progression, zone trigger volumes
- Stealth / aggro tied to light level
- BEST strip, chawl window grid, fairy lights
- Tilemap art pass (greybox ColorRect / simple polygons OK)
- New rival types, player dash/parry
- `bite_combat_helpers.gd` extraction
- Puddle slow zones, steam hazards

---

## Deliverable format (post-implementation)

1. Locked decisions table (above)
2. Research notes path + 8 bullets
3. Floorplan path + light graph ascii
4. Lamp table (position, radius, energy)
5. Emerge/spawn table
6. Files created / modified list
7. Lighting setup notes (CanvasModulate color, shadow on/off, layer masks)
8. F5 test script results (10 acceptance criteria)
9. Known limitations + v3.1 recommendations
10. Git commit SHAs

---

## Paste block (Codex)

```text
You are the gameplay engineering + lighting + level design team for Street Dog.

Project: /Users/aman.shrivastava/Documents/personal/projects/street-dog-draft
Branch: topdown-prototype
Engine: Godot 4.6 · GL Compatibility · GDScript · 2D only
Godot editor open · Godot Catalyst MCP Connected (port 6505).

READ (in order):
1. docs/codex-topdown-v3-light-street-prompt.md  (this spec — full authority)
2. docs/topdown-v3-light-street-design-brief.md
3. references/level1/ref1.jpeg … ref4.jpeg
4. Invoke $topdown-combat-expert — SKILL.md + knowledge-base.md

DO NOT ask the human questions. DO NOT reuse arena_mumbai_gully.gd topology.

MISSION — Topdown v3.0 vertical slice:
Build a NEW light-first Mumbai street segment (1920×1080 world) replacing the v2 arena.

LOCKED SCOPE:
- SINGLE WAVE: all 4 rivals at load; spawn dark → emerge into lamp pools
- SMALL SEGMENT: 2 sodium PointLight2D poles + 1 chai spill decal
- Hybrid layout: lit main wet run + one dark side gully (refs 3/4 + 1/2)
- CanvasModulate night + LightOccluder2D facades + hybrid painted spill
- 8-way movement; player Camera2D clamped to segment bounds
- Preserve: player bite v2, rival archetypes/FSM, prop verbs, gully clear respawn
- Update main_topdown.tscn to instance new street_segment_gully_01

DELIVER:
- docs/topdown-v3-light-street-research-notes.md (≥8 cited bullets)
- docs/topdown-v3-light-street-floorplan.md
- scenes/topdown/levels/street_segment_gully_01.tscn + scripts
- scenes/topdown/props/street_lamp_topdown.tscn
- street_wave_controller.gd (single-wave emerge)
- Wire arena_encounter respawn to new segment

PHASES 0→6 per spec. F5 after material changes. Logical git commits. Never push.

OUT OF SCOPE: zone waves, stealth/light aggro, BEST/windows/fairy lights, tilemap art pass.
```
