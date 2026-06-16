# Codex Task: Top-Down Level Redesign v2.2 — "Monsoon Gully Network"

**Purpose:** Rebuild the Mumbai night **street/gully** layout from scratch so it reads as
**outdoor forks and alleys**, not one big room with interior partitions and doors.

**Prerequisite:** v2.1 combat/enemy pass is **shipped** (commits `4138ade`, `f974149`).
This task is **layout + set dressing only**.

**Invoke skill:** `$topdown-combat-expert` — read SKILL + `knowledge-base.md` +
`docs/topdown-v2.2-level-research-notes.md` before coding.

**Branch:** `topdown-prototype` · **Engine:** Godot 4.6 · **Canvas:** 1280×720 single screen

**Do not ask the human questions.** Decisions below are locked.

---

## v2.1 completion audit (2026-06-16 — do NOT redo)

Codex already delivered the following. **Preserve as-is** unless a layout respawn
requires moving `RivalSpawn_*` markers only.

| Item | Status | Evidence |
|------|--------|----------|
| Research notes (≥10 bullets) | ✅ Done | `docs/topdown-v2.1-level-enemy-research-notes.md` |
| `BiteAttackProfile` resource | ✅ Done | `scripts/topdown/bite_attack_profile.gd` |
| `RivalArchetype` resource | ✅ Done | `scripts/topdown/rival_archetype.gd` |
| 4 archetype `.tres` | ✅ Done | `resources/topdown/archetypes/{stray,sentry,racer,bully}.tres` |
| Rival bite FSM (startup/active/recovery) | ✅ Done | `scripts/topdown/rival_dog.gd` |
| Forward wedge telegraph | ✅ Done | `Polygon2D` on rival scene |
| 4 rivals spawned by role | ✅ Done | `arena_mumbai_gully.gd` `_spawn_rivals()` |
| Soft room clear + respawn | ✅ Done | `arena_encounter.gd` → `gully clear` → `respawn_rivals()` |
| Chair kick → rival stagger | ✅ Done | `prop_plastic_chair.gd` (8f, no damage) |
| 7 props + laundry poles | ✅ Done | all prop scenes + positions in arena |
| Player bite v2 preserved | ✅ Done | not regressed in v2.1 commits |
| Mumbai dressing (partial) | ⚠️ Partial | chawl wall, 1 wire line, window drips, puddles, BEST stripe |
| Floorplan doc | ✅ Done | `docs/topdown-v2.1-floorplan.md` (superseded for layout) |
| Git commits | ✅ Done | `4138ade` specs · `f974149` implementation |

### v2.1 layout problems (why v2.2 exists)

Current `arena_mumbai_gully.gd` `_build_room()` uses **6 interior partition walls**
(`SpawnPartition_*`, `ForkDivider_*`, `BusPartition_*`, `LoopIsland_*`) inside one
1280×720 slab — reads as **rooms with doors**, not outdoor gullies.

| v2.1 gap | v2.2 fix |
|----------|----------|
| Partition-room topology | **Facade + lane graph** rebuild |
| Spawn is peek, not hidden | **Hidden nukkad** LOS audit |
| No chawl stairs | Loggia stairs + wadi step ring |
| Single overhead wire | **≥3** wire/drip elements over lanes |
| No LOS audit in floorplan | Required in `topdown-v2.2-floorplan.md` |
| `bite_combat_helpers.gd` | **Skipped** — optional in v2.1; still skip |

### Working tree note

Uncommitted Godot UID/resave churn on `archetypes/*.tres`, `arena_mumbai_gully.tscn`,
`default_tuning.tres`. **Do not strip explicit bite frame values** from archetype
`.tres` files when editing. Commit layout work in logical chunks when done.

---

## Critical creative freedom (read first)

| Rule | Meaning |
|------|---------|
| **Not bound to v2.1** | `topdown-v2.1-floorplan.md` and `arena_mumbai_gully.gd` wall graph are **reference only**. Delete/replace `_build_room()` topology entirely if needed. |
| **Not bound to "Chawl Fork" box** | The v2.1 ascii thumbnail is a failed pattern (partitioned playpen). Do **not** preserve its wall names, partition nodes, or pocket rects unless research justifies them. |
| **Rebuild allowed** | New building footprints, lane graph, prop scenes, decorative facades — **from scratch** — as long as combat systems below are preserved. |
| **Success test** | F5 for 30s: player describes where they are using **street words** (gully, by-lane, nukkad, chowk) — not room words (partition, door, courtyard room). |

---

## Locked human decisions

| Topic | Choice |
|-------|--------|
| **Identity** | Rainy night **Mumbai gully** — authentic outdoor lane network at dog scale |
| **Topology** | **Street graph** — main wet gully + side by-lane(s) + T/Y fork; building mass defines alleys |
| **Anti-pattern** | **Reject** single rectangle + interior `Partition_*` walls simulating rooms |
| **Density** | **Balanced** — GTA2-style smaller footprints + alleys; 80–140px exposure on lanes |
| **Routes** | **≥2 outdoor routes** between encounter pockets (main gully vs by-lane) |
| **Spawn** | **Hidden nukkad** — chai foothold; zero rival silhouettes until lane commit |
| **First fight** | **Stray** visible only after committing into gully/wadi — not fork ambush |
| **Retreat** | **Soft** — can return to chai nukkad; rivals leashed out of spawn band |
| **Hazards** | **None** — props/collision only |
| **Mumbai beats** | Chai nukkad, laundry on facade, BEST chowk, scooter, puddles, chawl stairs (loggia + wadi ring), wire tangles |
| **Scope** | **Layout + set dressing + arena builder** — preserve v2.1 **combat** (player bite v2, archetypes, room clear, prop verbs) |
| **Side-view** | Untouched |

---

## Phase 0 — Mandatory research (before greybox)

Write or extend `docs/topdown-v2.2-level-research-notes.md` (already seeded — add bullets only if you find new sources).

**Must read:**

| # | Source | Extract for Street Dog |
|---|--------|------------------------|
| 1 | [GTA2 buildings WikiGTA](https://en.wikigta.org/wiki/Creating_buildings_(GTA2)) | Small footprints + **alleys between** buildings |
| 2 | [GTA2 roads WikiGTA](https://en.wikigta.org/wiki/Creating_roads_(GTA2)) | Lane + pavement band; junctions as graph nodes |
| 3 | [GTA3 road hierarchy](https://iuliu-cosmin-oniscu.medium.com/open-world-analysis-gta-3-5c04c957a3eb) | Main → secondary → alley tier |
| 4 | [Disegno chawls](https://disegnojournal.com/newsfeed/the-making-and-raising-of-mumbai-housing) | wadi → gully → nukkad → chowk |
| 5 | [IJARSET chawl spaces](https://www.ijraset.com/best-journal/mumbai-chawls-resettlement-vs-chawl-culture-and-possible-solutions) | Named outdoor nodes |
| 6 | [Game Developer hallways](https://www.gamedeveloper.com/design/making-better-hallways) | Don't feel like interior corridors |
| 7 | [Michael Barclay arenas](https://mikebarclay.co.uk/my-level-design-guidelines/) | ≥2 exits per pocket; exterior forks |
| 8 | [Door problem](https://www.gamedeveloper.com/design/the-door-problem-of-combat-design) | Foothold on street edge, not behind door |

---

## Design method — macro → meso → micro

Follow [DOU level basics](https://gamedev.dou.ua/blogs/level-design-basics-part-2/):

### Step 1 — Macro (building footprints)

Place **chawl / shop blocks** as solid rectangles along arena edges and across the screen
to carve **negative-space lanes**. Think GTA2: *alleys between buildings*, not walls
inside an empty box.

Suggested massing (improve if research justifies):

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ CHAWL FACADE BAND (windows, laundry poles, wires, stairs down to lane)    │
├────────┬───────────────────────────────────────┬─────────────────────────┤
│ SHOP   │                                       │ CHAWL                   │
│ BLOCK  │     MAIN GULLY (wet paver lane)       │ BLOCK                   │
│        ├──────────────┬────────────────────────┤                         │
│ NUKKAD │   by-lane    │   WADI / CHOWK pocket  │   BEST CHOWK            │
│ chai   │   (narrow)   │   (wider, stray)       │   bench strip           │
│ spawn  │              │                        │   bully alcove          │
├────────┴──────────────┴────────────────────────┴─────────────────────────┤
│ CORRUGATED SHOP LIP / VENDOR SPILL (south facade)                          │
└──────────────────────────────────────────────────────────────────────────┘
```

- **≥4 building footprints** touching lane edges (north chawl, east chawl, west shop, south lip).
- **Lane graph** drawn on paper first: nodes = nukkad, fork, wadi, BEST chowk; edges = gully + by-lane.

### Step 2 — Meso (lane graph + forks)

| Node | Mumbai term | Combat role |
|------|-------------|---------------|
| Spawn band | **Nukkad** | Chai foothold; hidden LOS |
| Central fork | **Gully junction** | Sentry leash; T or Y |
| Wide pocket | **Wadi / chowk** | Stray patrol; scooter cover |
| Side path | **By-lane** | Racer skirmish; narrower |
| Bus strip | **BEST chowk** | Bully pressure |

**Lane widths (walkable tiles):**

| Tier | Width | Example |
|------|------:|---------|
| By-lane | 56–72px | laundry gap, rear alley |
| Main gully | 72–96px | wet central run |
| Chowk pocket | 120–200px | wadi opening (still **outdoor**, not walled room) |

**Fork rule:** At least one junction where **3 lane segments** meet visibly (T or Y).
Sentry owns the fork; does not chase into nukkad.

### Step 3 — Micro (props, sodium, wires)

- Props sit **in the lane** or **against facades** — not as random islands in a void room.
- Laundry poles **span between facades** (high cover) across a by-lane mouth.
- Wires drip from **chawl band** over lane (decorative Line2D / sprites).
- Stairs: **facade down to lane** (north) + **wadi step ring** (decorative).
- Puddles on main gully only; sodium pools on wet pavers.

---

## Hard layout constraints

1. **No playpen partitions:** Do not create ≥3 full-height interior walls that split one
   1280×720 rectangle into "rooms." Use **building shoulders** (opaque facade collision) instead.
2. **Outdoor read:** Every combat pocket must have **open sky band** (top 60–120px loggia/facade
   or visible lane ceiling = night rain) — not a closed interior ceiling.
3. **Hidden nukkad spawn:** 0 rival silhouettes from spawn; chai blocks LOS to all `RivalSpawn_*`.
4. **First sighting:** Stray in wadi/chowk after passing lane mouth — not Sentry in face at spawn.
5. **Cover spacing:** 80–140px between interactable islands **along lanes**.
6. **Camera:** Limits = 1280×720 playfield; no void gutters.
7. **Rival roles unchanged:** Stray wadi, Sentry fork, Racer by-lane, Bully BEST — positions may move anywhere on new graph.

---

## What to preserve from v2.1 (do not refactor)

| System | Files |
|--------|-------|
| Player bite v2 | `player_dog_topdown.gd`, `default_tuning.tres` preset B |
| Rival archetypes | `resources/topdown/archetypes/*.tres`, `rival_dog.gd` FSM |
| Bite profile | `bite_attack_profile.gd` |
| Room clear | `arena_encounter.gd` — `gully clear` → 2s respawn |
| Prop verbs | chair stagger, sack topple, box break, chai alert |

**Allowed / expected code touch:**

- `arena_mumbai_gully.gd` — **rewrite** `_build_room()` (footprints + lanes, not partitions)
- New scenes: `scenes/topdown/props/` — facade chunks, wire tangles, stair decals if needed
- Reposition all props for lane graph
- `docs/topdown-v2.2-floorplan.md` — **lane graph** + footprint table (not just pocket rects)

---

## Deliverables

1. **`docs/topdown-v2.2-floorplan.md`**
   - ASCII **lane graph** (nodes + edges labeled nukkad/gully/by-lane/chowk)
   - **Building footprint table** (rect, facade role)
   - **Lane segment table** (width, wet/dry, choke tier)
   - Spawn + rival marker table
   - Prop table (lane-relative positions)
   - **LOS audit** (spawn → each rival)
   - **Anti-pattern checklist** (signed off: no partition-room)

2. **`docs/topdown-v2.2-level-research-notes.md`** — extend if new sources found

3. **Implementation** — new arena topology in Godot; F5 playable

4. **Git** — logical commits on `topdown-prototype`; never push unless asked

---

## LOS audit (required)

| From spawn | Target | Requirement |
|------------|--------|-------------|
| Player | Stray | Blocked until lane commit |
| Player | Sentry, Racer, Bully | Blocked at nukkad |
| Player | Fork landmark | Partial — sodium at lane mouth only |
| Player | Main gully depth | Blocked or ≤1 facade corner peek |

---

## 60s F5 playtest script

1. **Nukkad:** 5s at spawn — no rivals; identify chai + lane mouth glow only.
2. **Street words:** After 30s player can say "main gully" vs "by-lane" without saying "room."
3. **Commit:** Enter gully — first rival is Stray in wadi/chowk pocket.
4. **Fork:** Sentry at junction; leashed out of nukkad.
5. **By-lane:** Reach Racer via side alley (not through a partition door).
6. **BEST:** Bully at chowk strip; readable on `#0E352E` stripe.
7. **Facade:** Laundry spans a lane gap; wires visible from lane.
8. **Regression:** Chair stagger + `gully clear` respawn unchanged.

---

## Paste block (Codex)

```text
You are working on Street Dog — Godot 4.6 2D at:
/Users/aman.shrivastava/Documents/personal/projects/street-dog-draft

Branch: topdown-prototype
Godot editor open · Godot Catalyst MCP Connected.

Read FULL spec: docs/codex-topdown-v2.2-level-redesign-prompt.md
Read research: docs/topdown-v2.2-level-research-notes.md
Invoke: $topdown-combat-expert (SKILL + knowledge-base.md)

v2.1 IS DONE (commits 4138ade, f974149). DO NOT redo:
- rival_dog.gd bite FSM, BiteAttackProfile, 4 archetype .tres
- arena_encounter.gd room clear, prop_plastic_chair stagger
- player_dog_topdown.gd attack feel

YOUR SCOPE: LAYOUT + SET DRESSING ONLY.

DELETE the v2.1 partition-room pattern in arena_mumbai_gully.gd _build_room():
SpawnPartition_*, ForkDivider_*, BusPartition_*, LoopIsland_* interior walls.

REPLACE with outdoor Mumbai gully lane network:
- Building footprints (facade collision) carve walkable alleys — GTA2 grammar
- Mumbai nodes: nukkad (chai spawn) → gully fork → wadi/chowk (Stray) → by-lane (Racer) → BEST chowk (Bully)
- Sentry leashed at fork; hidden spawn (zero rival silhouettes at nukkad)
- Add chawl stairs (loggia + wadi ring), ≥3 wire/drip elements, reposition all 8 props on lanes
- Keep 4 RivalSpawn_* roles; update positions only

Deliver:
1. docs/topdown-v2.2-floorplan.md (lane graph, footprint table, LOS audit, anti-pattern checklist)
2. Rewritten _build_room() + any new facade/stair/wire scenes
3. F5 60s playtest per spec
4. Logical git commits (never push)

DO NOT ask the human questions. DO NOT touch side-view scenes.
```
