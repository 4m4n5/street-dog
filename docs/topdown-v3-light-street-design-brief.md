# Topdown v3 — Light-First Mumbai Street Design Brief

**Status:** Course correction · replaces v1/v2/v2.2 layout assumptions
**Date:** 2026-06-16
**References:** `references/level1/ref{1-4}.jpeg`
**Human session:** locked decisions below — no Codex implementation until brief is approved.

---

## 1. What went wrong (v1 → v2.2)

We optimized for **combat pockets** (nukkad, fork, wadi, partition walls, footprint rects)
instead of **how Mumbai streets actually read at night from above**.

| Old assumption | Why it failed |
|----------------|---------------|
| Single 1280×720 “arena” | Streets are **segments**, not one room |
| `ColorRect` floor zones + walls | Reads as diagram / playpen, not pavement |
| Sodium as flat alpha slices | No **lamp pools**, no falloff, no shadow between poles |
| Layout-first, light-last | Refs show **light defines walkable path**; we painted paths then sprinkled glow |
| Combat graph drives geometry | Produced partition rooms (v2.1) then facade blocks (v2.2) — still not a **street** |
| Cyberpunk layout without cyberpunk art | Irregular ref1/ref2 **grammar** without their **lighting contrast** |

**Keep from prior work:** player bite v2, 4 rival archetypes, bite FSM, prop verbs, room-clear loop, tuning resources.
**Scrap for layout:** `arena_mumbai_gully.gd` builder topology, v2.2 floorplan as spatial target.

---

## 2. What the reference images teach

### ref1 + ref2 — Organic gully labyrinth (secondary grammar)

- **Irregular, non-cardinal** paths; multiple forks; not one rectangle.
- **Extreme contrast:** pitch-black between structures; color **spills** from signs and doorways.
- **Ground clutter** breaks up flat tiles: crates, barriers, puddles **in** light pools.
- **Steam / haze** softens pool edges (monsoon candidate later).
- **Takeaway for Mumbai:** side **by-lanes** and shop mouths are dark; signs and stalls **paint** the lane.

### ref3 — Arterial canyon (primary grammar, half)

- **Central lit corridor** (street-lamp rhythm) vs **dark building mass** on both sides.
- Mixed color temperature: cool street vs warm interior/parking spill.
- **Takeaway:** main gully = lamp-spaced pools along a wet run; chawls = dark shoulders.

### ref4 — Night intersection (primary grammar, half)

- **Circular amber pools** from poles on dark asphalt; islands create forks and chokes.
- Bright **nodes** at crossings; deep shadow between poles and beside buildings.
- **Takeaway:** sodium poles are the **spine** of navigation and combat readability.

### Hybrid model (locked)

> **Arterial lamp rhythm** along a wet main run **plus** irregular **side gullies**
> that stay dark until shop spill or a secondary lamp catches them.

---

## 3. Locked design decisions (human, 2026-06-16)

| Topic | Decision |
|-------|----------|
| **Layout model** | Hybrid — ref3/ref4 arterial + ref1/ref2 side alleys |
| **Map scale** | **Scrollable segment** — ~2–3 street-lamp spans; larger than one screen |
| **Travel** | **8-way free** — camera follows dog through segment |
| **Light gameplay (v3.0)** | **Readability + mood only** — no stealth/aggro rules yet |
| **Light tech** | **Hybrid** — Godot `Light2D` on lamps + painted decals for sign/window spill |
| **Combat** | **Keep 4 archetypes + room clear** AND **rivals emerge from dark alleys into lamp pools** |
| **Replay loop** | **Zone waves** (rivals activate per lamp zone) **+** full clear respawn **reshuffles** alley spawn points |
| **v3.0 slice (Codex)** | **Single wave** · **small segment** (1920×1080) · 2 poles + chai spill — see `codex-topdown-v3-light-street-prompt.md` |
| **Implementation** | **New level scene** — preserve player/rival/prop/encounter **code**, not arena builder |
| **Not tied to** | v2.1/v2.2 wall graphs, partition names, current prop positions |

---

## 4. Design pillars (ranked)

### Pillar 1 — Light leads layout

Per [Level Design Book — lighting](https://book.leveldesignbook.com/process/lighting):

1. Global night (ambient / `CanvasModulate`)
2. **Street-lamp wayfinding** (pole positions = path spine)
3. **Gameplay pools** (where rivals meet player)
4. Sign / window / chai **spill** (mood + zone identity)

**Rule:** Place lamp poles and their pool radii **before** collision footprints.

### Pillar 2 — Street, not arena

- Walkable surface = **continuous pavement/asphalt** with cracks, patches, puddles.
- Buildings = **dark mass** on edges; collision on facade, not interior partition walls.
- Forks happen at **intersections and shop mouths**, not `ForkDivider_*` nodes.

### Pillar 3 — Mumbai night identity via motivated lights

| Source | Color | Role | Phase |
|--------|-------|------|-------|
| **Sodium street pole** | Amber `#F28E42` pools | Path spine, zone anchors | **v3.0** |
| **Chai / shop spill** | Warm doorway wash | Nukkad identity, foothold | **v3.0** |
| **Chawl window grid** | Small warm rects | Facade rhythm, dark between | v3.1 |
| **BEST / bus strip** | Green + amber accent | Chowk landmark | v3.1 |
| **Fairy / festival string** | Optional accent | Seasonal beat | v3.2 |

Start with **sodium + shop spill**; add others as themed sub-zones within the segment.

### Pillar 4 — Dark alleys, lit fights

- **Spawn points** for rivals sit in **dark side gullies** (off-pool).
- On zone activate or aggro, rivals **move into** nearest lamp pool to fight (readable silhouettes).
- Player learns: **light = where the fight is**; dark = approach vector (readability only for now).

### Pillar 5 — Replay without new geometry

- **Zone waves:** entering lamp pool N can activate rivals tied to that zone.
- **Full clear:** `gully clear` → respawn all 4 at **reshuffled** dark-alley markers (not same corners every loop).

---

## 5. Proposed segment topology (v3.0 greybox)

Not a floorplan — a **light graph**. Approximate size TBD in implementation (likely 2400–3600px wide × 1600–2400px tall for 2–3 spans).

```text
     [chawl band — windows, optional fairy string later]
  ═══════════════════════════════════════════════════════
  ░░░ dark shop mass ░░  ═══ lamp ═══  ░░ dark chawl ░░
         ╲                      │                 ╱
          ╲  by-lane (dark)    │   by-lane     ╱
           ╲___________________│_______________╱
                    MAIN WET RUN (lamp pools ●───●───●)
  ═══════════════════════════════════════════════════════
     [corrugated lip / vendor spill — chai zone at seg start]
```

**Zones (lamp-tied):**

| Zone | Light anchor | Rivals (default) | Notes |
|------|--------------|------------------|-------|
| Z0 Nukkad | Chai spill + first pole | — | Player spawn; safe foothold |
| Z1 First pool | Pole 1 | Stray from dark W by-lane | Teaching fight |
| Z2 Fork pool | Pole 2 + shop mouth | Sentry from dark N cut | Junction read |
| Z3 Chowk pool | Pole 3 + BEST spill (v3.1) | Bully + Racer from E/W alleys | Pressure |

Camera: `Camera2D` follow player; limits = segment bounds; no void gutters.

---

## 6. Godot 4 technical direction

| Layer | Approach |
|-------|----------|
| Night base | `CanvasModulate` dark blue-grey **or** full-screen dark tint |
| Street lamps | `PointLight2D` + radial gradient texture; amber; **shadows on** with `LightOccluder2D` on facades |
| Shop spill | Painted `Sprite2D` / `ColorRect` gradients at doorways (no shadow cast) |
| Puddles | Dark decals that **brighten** inside lamp pools (additive or masked) |
| Characters | Ensure player/rivals render in lit layer; silhouette readable in pool |
| Performance | 3–6 active `PointLight2D` max in v3.0; pool overlap at intersections OK |

**Research:** [Catlike Coding — True Top-Down 2D lighting](https://catlikecoding.com/godot/true-top-down-2d/4-light-and-shadow/) · [GameDev.SE night pools](https://gamedev.stackexchange.com/questions/142249/how-can-i-create-lit-up-areas-during-night-time-in-a-top-down-2d-game)

---

## 7. What we keep vs replace

| Keep | Replace |
|------|---------|
| `player_dog_topdown.gd` | `arena_mumbai_gully.gd` as level builder |
| `rival_dog.gd` + archetypes | `main_topdown.tscn` arena instance → **new** `street_segment_*.tscn` |
| `arena_encounter.gd` (extend for zones) | ColorRect zone painting |
| Prop scripts (chair, sacks, …) | Prop **placement** (lane-relative to lamps) |
| `bite_attack_profile.gd` | v2.x floorplan docs as **historical** only |

**New systems (v3):**

- `street_lamp.gd` — pole visual + `PointLight2D` + zone id
- `street_zone.gd` — lamp pool bounds, rival spawn markers, wave activate
- `street_segment.gd` — builds pavement, facades, registers zones
- `docs/topdown-v3-light-street-floorplan.md` — light graph + segment bounds (when greyboxing)

---

## 8. Success criteria (first playtest)

1. **Night read:** segment is dark; **pools** read before walls/pockets.
2. **Street words:** “main lane”, “side gully”, “under the lamp” — not “room” or “partition”.
3. **Scroll:** 8-way move through ≥2 lamp spans without seeing void.
4. **Fight in light:** rivals visible when they enter pools; approach from darker gaps.
5. **Replay:** second clear spawns rivals from **different** alley markers.
6. **Combat unchanged:** bite feel, telegraphs, chair stagger, `gully clear` still work.

---

## 9. Open items (next human pass)

1. **Segment dimensions** — exact px size for 2 vs 3 lamp spans (greybox in editor).
2. **Phase-1 lamp count** — confirm 3 poles + 1 chai spill for v3.0 greybox.
3. **Zone wave trigger** — enter pool vs kill previous zone vs both.
4. **Art pipeline** — tilemap vs procedural ColorRect pavement for v3.0.
5. **Side-view** — still untouched; confirm topdown entry scene points to new segment.

---

## 10. Deprecated docs

| Doc | Status |
|-----|--------|
| `codex-topdown-v1-level-design-prompt.md` | Historical |
| `codex-topdown-v2.2-level-redesign-prompt.md` | **Superseded** by this brief |
| `topdown-v2.1-floorplan.md`, `topdown-v2.2-floorplan.md` | Reference only — do not implement |

**Next artifact:** `codex-topdown-v3-light-street-prompt.md` — **implementation spec (locked v3.0 slice).**
