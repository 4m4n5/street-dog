# Codex Task: Top-Down Level Redesign + Competitive Rival Dogs v2.1

Copy the **paste block** at the bottom into a new Codex thread. Godot editor must be open with Godot Catalyst **Connected**.

**Invoke skill:** `$topdown-combat-expert` — read `~/.cursor/skills/topdown-combat-expert/SKILL.md` + `knowledge-base.md` before coding.

**Scope:** **Level design from scratch** + **more rivals** + **rival bite combat rebuilt to mirror player attack quality**. This is the companion pass to attack-feel v2 (already shipped on `topdown-prototype`).

**Do NOT regress** player bite feel (`player_dog_topdown.gd` buffer, hit-stop, whiff/connect juice). Touch player code only if extracting shared bite modules.

**Branch:** `topdown-prototype`

**Do not ask the human questions.** All decisions are locked below. Start Phase 0 immediately.

---

## Locked human decisions (final — do not re-ask)

| Decision | Choice |
|----------|--------|
| **Rival count** | **4** — Stray, Sentry, Racer, Bully (no scavenger) |
| **Encounter end** | **Soft room clear** — all rivals dead → ~1.5s beat (lowercase label + SFX) → respawn rivals at markers; player HP unchanged |
| **Props** | Reposition all 7 existing props + **one new prop:** laundry-line poles (high cover, Mumbai chawl) + implement **chair-into-rival** light stagger if cheap (kicked chair contacts rival → brief stagger, no extra damage) |
| **Git** | **Logical commits** on `topdown-prototype`; **stage and commit** previously untracked `scenes/topdown/`, props, HUD, arena; never push unless asked |
| **Layout** | Redesign from scratch — not v1 three-pocket |
| **Setting** | Rainy night Mumbai gully / chawl, single **1280×720** screen |
| **Combat** | Rival lunge-bite parity with player; balanced difficulty |
| **Player attack** | Preserve v2 feel — no regressions to buffer/juice/hit-stop |
| **Side-view** | Untouched |

---

## Human intent (design goals)

| Topic | Decision |
|-------|----------|
| Layout | **Redesign from scratch** — do not copy v1 "Gully Three-Pocket" wall graph verbatim |
| Setting | Rainy night **Mumbai gully / chawl lane** — same identity, new topology |
| Screen | Single **1280×720** arena (no multi-room transitions v2.1) |
| Rivals | **Rival dogs only** — no humans, no projectiles v2.1 |
| Combat parity | Rivals use **same bite grammar** as player: startup → lunge active → recovery vulnerability |
| Difficulty | **Balanced** — telegraphs fair; failures feel earned (Game Developer door-problem + attack phases) |
| Player attack | **Preserve v2** tuning (`default_tuning.tres` preset B) unless extracting shared profile |
| Side-view fork | **Untouched** — `main.tscn`, `dog.tscn`, `street_night.tscn` |

---

## Phase 0 — Mandatory internet research

Write `docs/topdown-v2.1-level-enemy-research-notes.md` with **≥10 cited bullets** + URLs.

| # | Topic | Sources to use |
|---|-------|----------------|
| 1 | Hotline room clarity, sightlines, commitment | Steam HL:M guide, door-problem article |
| 2 | Choke / loop / foothold layout | WoLD chokepoints, CritPoints loops |
| 3 | Hades room kits & encounter pacing | Kotaku / Ed Gorinstein thread |
| 4 | Attack phases: anticipation / attack / recovery | recited.io attack pattern design |
| 5 | Telegraph timing ladder (ms → frames @60) | gamineai telegraph audit 2026 |
| 6 | Post-attack vulnerability windows | Chaotic Stupid telegraphs 2 |
| 7 | Top-down VFX lanes (enemy vs player hue) | gamineai color timing 2026 |
| 8 | Gungeon environmental verbs | Game Developer Gungeon Q&A — chair stagger only this pass |
| 9 | Mumbai chawl / gully spatial identity | Architizer chawls, prior Street Dog palette |
| 10 | Godot patterns | CharacterBody2D floating, shared Resources |

### Phase 0 deliverable — layout + combat targets (10–15 bullets)

Include measurable rules, e.g.:

- Arena readable in **<3 seconds**; **≥2 routes** between pockets (loop, not corridor)
- **≥1 foothold** at spawn before LOS to multiple threats
- **≥2 chokes** at different widths (narrow commit + wider flank)
- Rival bite telegraph: **forward wedge** (not bar above head); enemy hue **distinct** from player windup
- Medium-punishment telegraph band: **~650–900ms** (~39–54f @60) for bully; low band for skirmisher
- **Recovery vulnerability** ≥ player punish window (rival recover ≥ player active+startup or explicit stagger)

---

## What exists today (replace / refactor)

| Asset | Status |
|-------|--------|
| `arena_mumbai_gully.gd` | v1 three-pocket — **replace** `_build_room()` topology |
| `docs/topdown-v1-floorplan.md` | Reference only — **new** `docs/topdown-v2.1-floorplan.md` |
| `rival_dog.gd` | Simple chase → windup → bite; **refactor** to shared bite FSM + archetypes |
| `topdown_tuning.gd` | Global rival constants — **split** into per-archetype `RivalArchetype` resources |
| Player `player_dog_topdown.gd` | v2 attack feel — **preserve behavior** |
| Props (7 types) | Keep scripts; **reposition** for new layout |

---

## Level design brief — "Chawl Fork" (design target, not copy-paste)

Design a **new** 1280×720 floor plan. Name it in your floorplan doc. Suggested topology (you may improve if research justifies):

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ CHAWL LOGGIA (windows, wires, sodium pools)                                 │
├── SPAWN FOOTHOLD ──choke──┬── MAIN WET LANE ──────┬── BUS / BEST ALCOVE ──┤
│   chai + clutter          │   chairs, puddles      │   bench, boxes         │
│                           ├── FORK (T junction) ───┤   sentry leash        │
│                           │         │              │                        │
│                           │    COURTYARD WELL     │   bully / racer        │
│                           │    scooter, sacks     │                        │
│                           └── rear choke ─────────┴── side loop (flank) ───┤
│ CORRUGATED SHOP LIP + vendor spill                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

### Layout rules (enforce)

1. **Foothold:** spawn behind high cover; cannot see all rivals at once
2. **Door problem fix:** internal cover before first exposure lane (Game Developer)
3. **Two chokes:** one **56–72px** (commit), one **88–110px** (flank/loop)
4. **Cover spacing:** 80–140px between islands; mix high/low tiers
5. **Leash zones:** at least one rival **short-leash** at choke (doesn't chase to spawn)
6. **Prop verbs:** reposition props; add **laundry-line poles**; chair kick can **stagger** a rival on contact
7. **Sodium + wet** readability on main lane; not a grey box

Document final coords in `docs/topdown-v2.1-floorplan.md` (ascii, pocket rects, wall table, spawn table, prop table).

---

## Rival dog system — competitive bite parity

### Problem

Player bite (v2) has: 2f startup, lunge active, recovery, buffer, connect juice. Rivals still use **older chase + range check + generic windup** — feels like a different game.

### Solution — shared bite profile

Create:

```
scripts/topdown/bite_attack_profile.gd   # class_name BiteAttackProfile extends Resource
scripts/topdown/rival_archetype.gd       # class_name RivalArchetype extends Resource
resources/topdown/archetypes/*.tres      # one per role
```

**`BiteAttackProfile`** fields (mirror player `@export` names where possible):

- `startup_frames`, `active_frames`, `recovery_frames`, `recovery_move_unlock`
- `startup_speed_mult`, `lunge_speed`
- `hitbox_offset`, `hitbox_size`
- `knockback_target`, `self_knockback`, `hit_stop_sec` (rivals: on player hit)
- `windup_telegraph_alpha`, `telegraph_color` (enemy lane — amber/red, not player gold)

**`RivalArchetype`** fields:

- `display_name`, `max_hp`, `move_speed`, `detection_range`, `leash_radius` (0 = full chase)
- `patrol_radius`, `body_color`, `head_color`, `shoulder_scale`
- `bite: BiteAttackProfile`
- `ai_role: StringName` — `patrol` | `leash` | `skirmish` | `bully`

### Archetypes to ship (exactly 4)

| Role | ID | HP | AI | Spawn pocket | Bite feel vs player |
|------|-----|---:|-----|--------------|---------------------|
| **Stray** | `stray` | 2 | Patrol courtyard well | Courtyard | ~90% player frames; teaching enemy |
| **Sentry** | `sentry` | 2 | Leash at fork choke | Fork / main choke | Slower lunge, **longer telegraph** |
| **Racer** | `racer` | 2 | Skirmish flank loop | Side loop lane | Faster lunge, **shorter telegraph** |
| **Bully** | `bully` | 3 | Bus / BEST alcove pressure | Bus alcove | Heavy knockback, long recover window |

### Rival FSM (refactor `rival_dog.gd`)

```
IDLE/PATROL → CHASE (if detected & in leash) → BITE_STARTUP → BITE_ACTIVE → BITE_RECOVERY → STAGGER on hit → DEAD
```

- **BITE_*** states use same math as player lunge (velocity along facing)
- **Forward wedge telegraph** during startup (reuse Polygon2D pattern from player)
- **Recovery** is vulnerability — do not immediately re-chase if player in bite range
- `take_hit()` — keep stagger sync with player hit-stop (v2 behavior)
- Attack player via `receive_enemy_hit` on connect during **BITE_ACTIVE** only
- **Separation** between rivals preserved; add simple anti-stack nudge

### Tuning alignment (starting points — playtest and `@export`)

Player preset B (do not weaken): startup 2f, active 3f, recovery 10f, lunge 540, hit-stop 0.055s.

| Archetype | Startup | Active | Recover | Lunge | Telegraph |
|-----------|--------:|-------:|--------:|------:|-----------|
| Stray | 3f | 3f | 12f | 500 | medium |
| Sentry | 5f | 3f | 14f | 460 | long (fair) |
| Racer | 2f | 3f | 10f | 580 | short |
| Bully | 4f | 4f | 16f | 520 | long + heavy KB |

---

## Arena + spawn integration

### `arena_mumbai_gully.gd`

- Replace `_build_room()` with new topology from floorplan doc
- Replace `_spawn_rivals()` with data-driven spawn from `RivalArchetype` array on tuning or arena `@export`
- Add spawn markers: `RivalSpawn_Stray`, `RivalSpawn_Sentry`, `RivalSpawn_Racer`, `RivalSpawn_Bully`
- `sync_rival_tuning()` applies global + archetype resources
- Keep `get_spawn_position()` for player respawn

### `topdown_tuning.gd`

- Keep player + arena palette groups
- Replace single `rival_*` attack constants with **defaults on archetype .tres** files
- Keep legacy `spawn_rival_a/b` deprecated or map to new markers for one release — document in deliverable

### Room clear (required)

- `scripts/topdown/arena_encounter.gd` on arena or main: track `rival_dog` group living count
- On 0 → `encounter_cleared` → `CanvasLayer` label **"gully clear"** (lowercase, street tone) + `GameSfx` → respawn all 4 rivals after **2s**; player HP unchanged

### New prop — laundry line

- `scenes/topdown/props/laundry_line_poles.tscn` + `scripts/topdown/props/prop_laundry_line.gd`
- High cover (`StaticBody2D`), two poles + decorative line `Line2D` (no collision on line)
- Mumbai chawl identity; place on loggia edge per floorplan

### Chair → rival stagger

- Extend `prop_plastic_chair.gd` or chair `Area2D`: while sliding, if body in group `rival_dog` and rival not DEAD → call rival `take_hit(0, knockback_from_chair, 0)` or dedicated `apply_stagger(frames)` — **6–10f stagger**, no HP loss

---

## Architecture — files

### Create

| Path | Purpose |
|------|---------|
| `docs/topdown-v2.1-level-enemy-research-notes.md` | Phase 0 |
| `docs/topdown-v2.1-floorplan.md` | Authoritative layout |
| `scripts/topdown/bite_attack_profile.gd` | Shared bite numbers |
| `scripts/topdown/rival_archetype.gd` | Archetype resource |
| `resources/topdown/archetypes/{stray,sentry,racer,bully}.tres` | Four archetypes |
| `scripts/topdown/arena_encounter.gd` | Soft room clear |
| `scenes/topdown/ui/encounter_clear_topdown.tscn` | "gully clear" beat |
| `scenes/topdown/props/laundry_line_poles.tscn` | New Mumbai prop |
| `scripts/topdown/props/prop_laundry_line.gd` | High cover prop |

### Major edit

| Path | Action |
|------|--------|
| `scripts/topdown/rival_dog.gd` | Bite FSM + archetype profile |
| `scripts/topdown/arena_mumbai_gully.gd` | New layout + spawn table |
| `scenes/topdown/arena_mumbai_gully.tscn` | New markers |
| `scenes/topdown/rival_dog.tscn` | Telegraph wedge parity |
| `scripts/topdown/main_topdown.gd` | Wire encounter clear if needed |
| `scripts/topdown/topdown_tuning.gd` | Spawn slots / archetype refs |

### Optional extract (only if clean)

| Path | Purpose |
|------|---------|
| `scripts/topdown/bite_combat_helpers.gd` | Shared hitbox enable, wedge telegraph factory |

### Do NOT break

- `player_dog_topdown.gd` attack feel (buffer, coyote, juice)
- Side-view scenes
- Physics layers: 1 world, 2 player, 3 enemies, 4 interactables

---

## Implementation phases

| Phase | Work | F5 gate |
|-------|------|---------|
| **0** | Research doc | — |
| **1** | Floorplan doc + markers | Load arena |
| **2** | `BiteAttackProfile` + 4 archetype `.tres` | Inspector |
| **3** | Refactor `rival_dog.gd` bite FSM | 1 stray lunge bite |
| **4** | Rebuild arena + props + laundry line | Layout matches doc |
| **5** | Spawn 4 archetypes + AI roles | Full encounter |
| **6** | Room clear + chair stagger + git commits | 60s playtest |

---

## Success criteria (60s playtest)

1. **New layout** — clearly not v1 three-pocket; readable in <3s
2. **≥2 routes** — loop/flank exists; spawn foothold works
3. **4 rivals** — distinct roles at spawn pockets above
4. **Rival bite** — lunge + wedge telegraph + recovery punish window; not "contact slap"
5. **Fair trades** — player can dodge telegraph and punish recovery (balanced)
6. **Player bite unchanged** — buffer + connect still feel as before
7. **Mumbai night** — sodium, wet lane, chawl, chai, BEST still read
8. **All archetype + bite values** tunable in Inspector

---

## Deliverable format

1. Locked decisions table (copy from spec — no Q&A)
2. Research notes path + 8 layout/combat targets
3. Floorplan doc path + ascii thumbnail
4. Archetype table (role → .tres → spawn → behavior)
5. Bite parity table (player vs each archetype frames)
6. AI leash/skirmish notes
7. Files touched (include newly tracked scenes)
8. F5 test script — spawn → fork → loop → kill 4 → "gully clear" → respawn
9. Known limitations — pack AI, parry, dash, full prop-kills v2.2
10. Git — list commit SHAs (logical chunks + staged scenes)

---

## Godot 4 notes

- `set_deferred` for hitbox toggles in signal callbacks
- Rival bite direction: toward player at **windup start** (locked for active)
- Hit-stop on player: use existing `receive_enemy_hit`; rivals use lighter stop on player connect if needed (≤0.03s)
- Group `rival_dog` for encounter counting; group `hurtbox` for player hits

Work phase 0 → 6. **Do not ask the human questions.**

---

## Paste block (for Codex)

```
You are working on Street Dog — Godot 4.6 2D at:
/Users/aman.shrivastava/Documents/personal/projects/street-dog-draft

Read AGENTS.md, invoke $topdown-combat-expert (SKILL + knowledge-base), and the FULL task spec:
docs/codex-topdown-v2.1-level-enemies-prompt.md

Godot editor open · Godot Catalyst MCP Connected (port 6505).

DO NOT ask the human any questions. All decisions are locked in the spec.

LOCKED:
- 4 rivals: Stray, Sentry, Racer, Bully — lunge-bite parity with player (BiteAttackProfile FSM)
- New arena layout FROM SCRATCH ("Chawl Fork" topology — NOT v1 three-pocket)
- Soft room clear: all dead → "gully clear" beat ~1.5s → respawn 4 rivals in 2s
- Props: reposition existing 7 + NEW laundry-line poles + chair-kick staggers rival (no damage)
- Preserve player v2 attack feel (buffer, hit-stop, juice) — no regressions
- Git: logical commits on topdown-prototype; stage+commit untracked scenes/topdown; never push

PHASE 0: Research → docs/topdown-v2.1-level-enemy-research-notes.md
Then phases 1→6 per spec. F5 after each major phase.
DO NOT break side-view scenes (main.tscn, dog.tscn, street_night.tscn).
Output deliverable format from the doc.
```
