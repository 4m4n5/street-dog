# Codex Task: Top-Down Attack Feel v2 (Hades-Inspired)

Copy the **paste block** at the bottom into a new Codex thread. Godot editor must be open with Godot Catalyst **Connected**.

**Invoke skill:** `$topdown-combat-expert` — read `~/.cursor/skills/topdown-combat-expert/SKILL.md` + `knowledge-base.md` before coding.

**Scope:** **Attack feel only** — do NOT redesign the level, add rooms, or implement prop-kills / new props in this pass. Level redesign and environmental combat depth are **v2.1+** (document ideas only in research notes).

**Branch:** `topdown-prototype` (already exists; uncommitted v1 work may be present).

---

## ⚠️ STOP — Ask the human first (before any code)

Present these **three questions** in your first reply. **Wait for answers** unless the human says "use defaults". Do not skip.

### Q1 — Steering during lunge

How much can the player steer during bite **active** frames?

| Option | Behavior |
|--------|----------|
| **A (Recommended)** | **Hades-style commit** — no steering during active lunge; full 8-way move unlocks from `attack_recovery_move_unlock` frame onward |
| **B** | Slight steering during active (e.g. 15–25% velocity blend toward input) |
| **C** | Full lock until recovery ends |

**Default if no answer:** A

### Q2 — Whiff feedback

What happens on bite whiff (no target hit)?

| Option | Behavior |
|--------|----------|
| **A (Recommended)** | Subtle whiff package — short snort/grunt procedural SFX + tiny forward dust puff (no hit-stop, no camera punch) |
| **B** | Silence + recovery only — whiff is the punishment |
| **C** | Stronger whiff — longer recovery extension on whiff (+2–4 frames) plus option A feedback |

**Default if no answer:** A

### Q3 — Git commits

Should you commit on `topdown-prototype`?

| Option | Behavior |
|--------|----------|
| **A** | **No commits** — leave changes unstaged for human review |
| **B (Recommended)** | Logical commits on `topdown-prototype` only (e.g. tuning → buffer → juice → rival sync) — never push unless asked |
| **C** | Single commit at end |

**Default if no answer:** B

---

## Human decisions already locked (do not re-ask)

| Topic | Decision |
|-------|----------|
| Feel north star | **Hades** — snappy commit, readable weight, strong hit-stop on connect |
| Alternate styles | **Document only** in research notes (Hotline / Nuclear Throne / Gungeon) for human's next round — do not ship preset switchers |
| Mechanics this pass | **Tune** frame data + knockback + hit-stop **and** full **input buffer** package |
| Input buffer | Queue 1 bite + buffer into startup from recovery + **coyote bite** (brief window after movement stops, bite last facing) |
| Juice tier | **Subtle** — no screen-filling particles or heavy shake |
| Blockout++ | **All light**: bite windup telegraph, connect hit flash, small directional particles, tiny camera offset on connect (not kill-tier shake) |
| SFX | **Minimal** — procedural `GameSfx` only; no new audio files unless trivial one-line extension |
| Rivals | **Sync stagger** to player hit-stop on connect |
| Encounter | **Sandbox** — no room-clear / win state |
| Difficulty | **Balanced** — fair telegraphs; lethal but readable |
| Bite problem | **You benchmark** — play F5, propose A/B tuning table with rationale |
| Level / props | **Out of scope** — do not redesign floor plan or add prop-kills |

---

## Phase 0 — Mandatory internet research (before code, after human answers Q1–Q3)

Write or append `docs/topdown-v2-attack-research-notes.md` with **≥8 cited bullets** and URLs.

### Research questions

| # | Topic | Start here |
|---|-------|------------|
| 1 | Hades attack feel — commit, recovery, hit-stop | Kotaku/Gorinstein Hades design; kindatechnical hit-stop |
| 2 | Input buffering for action games | kindatechnical input buffering; fighting-game buffer windows |
| 3 | Juice intention matrix — subtle tier | gamejuice.co.uk juice intention matrix |
| 4 | Hit-stop / knockback tuning bands | sensecentral hit feedback; game-designers.net game feel |
| 5 | Top-down melee readability | Game Developer environment layout / telegraph visibility |
| 6 | Godot 4 implementation | Godot CharacterBody2D docs; existing Street Dog patterns |
| 7 | Coyote-time analog for attacks | Document whether coyote applies to facing-at-press vs post-move-stop |
| 8 | Alternate styles (doc only) | Hotline instant melee vs Nuclear Throne knockback — 3-bullet comparison table |

### Phase 0 deliverable — feel targets (8–12 bullets)

Merge research + human answers into actionable rules, e.g.:

- Hades-like **commit** on lunge (per Q1)
- Hit-stop **only on connect**, not whiff (per Q2)
- Buffer window targets in **frames @ 60fps** with `@export` tunables
- Juice scales: whiff < graze prop < connect < kill (kill = both rivals dead, optional micro-beat only)

---

## Current codebase (read via MCP — do not invent paths)

| Asset | Role |
|-------|------|
| `scripts/topdown/player_dog_topdown.gd` | Player FSM: MOVE / ATTACK_* / HITSTUN |
| `scripts/topdown/rival_dog.gd` | Rival FSM; `take_hit(damage, knockback, hit_stop)` |
| `scripts/topdown/topdown_tuning.gd` | `TopdownTuning` — extend with buffer + juice exports |
| `resources/topdown/default_tuning.tres` | Shared tuning |
| `scripts/audio/game_sfx.gd` | Procedural SFX autoload |
| `scenes/topdown/main_topdown.tscn` | Entry |
| `docs/topdown-v1-floorplan.md` | **Do not change layout this pass** |

**Existing attack flow:** 3f startup → 3f active lunge @ 520px/s → 10f recovery (move unlock frame 6). Hit-stop 45ms global `time_scale`. Visual scale tween on bite. No buffer.

---

## Phase 1 — Benchmark & tuning proposal

1. F5 playtest current build **before** edits (note whiff vs connect vs diagonal choke feel).
2. Produce **A/B/C tuning table** in deliverable:

| Preset | Intent | Key deltas |
|--------|--------|------------|
| **A — Current** | Baseline | existing `default_tuning.tres` |
| **B — Hades-leaning (ship this)** | Snappier commit, stronger connect stop | your recommended defaults |
| **C — Hotline-leaning (doc only)** | Shorter total frames, less recovery | numbers for research notes only |

3. Implement **preset B** into `default_tuning.tres` after human approves table OR if human said "use defaults".

### Suggested starting exports (tune after playtest — all must be `@export`)

Add `@export_group("Player Attack Buffer")` to `topdown_tuning.gd`:

```
attack_buffer_frames          = 8     # queue bite press during recovery
attack_coyote_frames          = 6     # after move stops, keep last facing for bite
attack_recovery_buffer_frames = 4     # late recovery presses skip to startup
```

Add `@export_group("Player Attack Juice")`:

```
attack_windup_telegraph_alpha   = 0.55   # forward wedge/snout flash during startup
attack_connect_flash_sec        = 0.06
attack_whiif_dust_enabled       = true   # respect Q2
attack_camera_nudge_px          = 3.0    # on connect only
attack_camera_nudge_sec         = 0.05
```

Adjust existing bite group toward Hades-leaning B (example — **verify in playtest**):

```
attack_startup_frames       = 2–3
attack_active_frames        = 3–4
attack_recovery_frames      = 8–12
attack_lunge_speed          = 480–560
attack_hit_stop_sec         = 0.05–0.07   # connect only
attack_knockback_target     = 140–180
attack_self_knockback       = 40–55
```

---

## Phase 2 — Input buffer implementation

Implement in `player_dog_topdown.gd`:

### Buffer rules

1. **Queue one bite** — if `attack` pressed during `ATTACK_RECOVERY` or `HITSTUN` (optional: exclude hitstun — document choice), set `_buffered_attack = true`; consume on entering `MOVE` or at recovery move-unlock (document which feels better in playtest).

2. **Recovery → startup buffer** — presses in last `attack_recovery_buffer_frames` of recovery transition directly to `ATTACK_STARTUP` on recovery end (no extra MOVE frame).

3. **Coyote bite** — after `direction == ZERO`, decrement coyote counter each physics frame; `_choose_bite_direction()` may use `_last_move_direction` while coyote > 0.

### Constraints

- Do not buffer during `ATTACK_STARTUP`/`ATTACK_ACTIVE` unless you document double-tap risk and keep one bite per lunge.
- Bite direction lock at **press** time for buffered attacks (store `_buffered_direction`).

---

## Phase 3 — Blockout++ juice (subtle)

All on `Visual` or child nodes — no sprite sheets.

| Effect | When | Implementation hint |
|--------|------|---------------------|
| **Windup telegraph** | Startup | Forward `ColorRect` or `Polygon2D` wedge, local +X, fades in |
| **Connect flash** | Hit rival/prop with damage | Brief modulate on target + player snout |
| **Dust puff** | Whiff (Q2A) or connect | 3–5 `ColorRect` particles, short tween, pool or one-shot |
| **Camera nudge** | Connect only | `Camera2D.offset` bump opposite bite dir, tween back — **no** trauma shake |

**Do not** add heavy screen shake. Respect readability (KB §Juice intention matrix).

---

## Phase 4 — Rival stagger sync

In `rival_dog.gd` `take_hit()`:

- When `hit_stop > 0`, rival enters `STAGGER` for frames derived from hit-stop OR explicit `tuning.rival_stagger_frames` synced to player stop duration.
- Ensure rival velocity/knockback applies on same frame as player hit-stop starts.
- Windup telegraph (forward wedge) unchanged unless needed for balance — document any windup frame tweak.

**Balanced check:** player can punish a whiffing bully in courtyard without instant trade damage — playtest and note.

---

## Phase 5 — SFX (minimal)

Extend `game_sfx.gd` only if needed:

- `play_bite_whiif()` or reuse `play_bite` with lower pitch — whiff only (Q2)
- Keep `play_hit` on connect

No imported `.wav` files this pass.

---

## Phase 6 — Alternate feel styles (documentation only)

Append to `docs/topdown-v2-attack-research-notes.md`:

| Style | Frame philosophy | Juice | When to try |
|-------|------------------|-------|-------------|
| Hotline-leaning | Near-zero startup, short recovery | Minimal stop | Next human round |
| Nuclear Throne-leaning | Higher knockback, longer stagger | More knockback VFX | Next human round |
| Gungeon-leaning | Prop synergy on bite | Clang + alert radius | v2.1 level pass |

**Do not** implement runtime preset switcher or debug keys 1/2/3.

---

## Explicitly out of scope

- Level redesign / new floor plan / new partitions
- Prop-kills, new Mumbai props, hazards, puddle slow
- Dash, parry, combo chain, charged bite, wall slam
- Room clear UI / win state
- Side-view scene changes (`main.tscn`, `dog.tscn`, `street_night.tscn`)
- Sprite sheets / Kenney art import

---

## Success criteria (60s human playtest)

1. **Connect feels Hades-snappy** — commit on lunge, satisfying stop on hit, not mushy
2. **Buffer works invisibly** — spamming J during recovery still feels intentional, not dropped inputs
3. **Coyote** — releasing movement then biting still hits expected direction
4. **Whiff** — per Q2 answer; not confused with connect
5. **Rival** — stagger reads on same beat as player hit-stop
6. **No level regressions** — v1 three-pocket layout unchanged
7. **All new values** `@export` in `TopdownTuning`

---

## Deliverable format

When done, report:

1. **Human Q1–Q3 answers** (or "used defaults")
2. **Research notes** path + 5 feel targets
3. **A/B/C tuning table** with final shipped values
4. **Buffer spec** — frames, state diagram (ascii)
5. **Juice checklist** — what was added per effect
6. **Rival sync** — stagger timing vs hit-stop
7. **Files touched** table
8. **F5 test script** — 60s steps (include whiff, buffer, diagonal bite in choke, rival stagger)
9. **Known limitations** — deferred to v2.1 level / v0.3 mechanics
10. **Git** — commit SHAs if Q3=B/C, else "uncommitted"

---

## Godot 4 notes

- Keep `set_deferred` for hitbox monitoring toggles in callbacks
- Hit-stop: `Engine.time_scale = 0` + `create_timer(..., ignore_time_scale=true)` — ensure `_exit_tree` resets scale
- Frame math: `frames_to_seconds(f) = f / 60.0` unless project physics FPS differs — read `project.godot`
- F5 after each phase; fix errors before continuing

Work **phase 0 → 6**. Ask Q1–Q3 first.

---

## Paste block (for Codex)

```
You are working on Street Dog — Godot 4.6 2D at:
/Users/aman.shrivastava/Documents/personal/projects/street-dog-draft

Read AGENTS.md, invoke $topdown-combat-expert (SKILL + knowledge-base), and the FULL task spec:
docs/codex-topdown-v2-attack-feel-prompt.md

Godot editor open · Godot Catalyst MCP Connected (port 6505).

FIRST MESSAGE: Ask the human the three questions in the "STOP — Ask the human first" section (steering during lunge, whiff feedback, git commits). Wait for answers or "use defaults" before coding.

Then on branch topdown-prototype:
- PHASE 0: Internet research → docs/topdown-v2-attack-research-notes.md
- ATTACK FEEL ONLY: Hades-inspired tune + full input buffer + subtle blockout++ juice
- Sync rival stagger to player hit-stop
- Benchmark A/B/C tuning; ship Hades-leaning preset B
- Document Hotline/Nuclear/Gungeon alternates in research notes ONLY
- DO NOT redesign level, add prop-kills, dash, parry, or win state
- DO NOT break side-view scenes

Work phases 0→6. F5 after each phase. Output deliverable format from the doc.
```
