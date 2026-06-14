# Codex Task: Jump v1 + Street Bite Attack v0

Copy this entire file into a new Codex thread. Godot editor must be open with Godot Catalyst **Connected**.

---

## Task: Implement Jump v1 + Street Bite Attack v0 (player combat foundation)

Read `street-dog-draft/AGENTS.md` and `README.md` first.
Godot 4.6 · 2D only · GL Compatibility · GDScript only.

**Before coding:** Use Godot Catalyst MCP to inspect `scenes/player/dog.tscn`,
`scripts/player/dog.gd`, and `scenes/levels/street_night.tscn`. Never invent node paths.
Run F5 after each phase; fix errors before proceeding.

---

## Phase 0 — Research pass (do this first, briefly document findings)

Before implementing, do a short literature / reference sweep using your own knowledge
and any available resources. Synthesize into a **5–10 bullet "feel target"** note at
the top of your deliverable. Prioritize:

| Source family | What to extract |
|---------------|-----------------|
| **Hollow Knight** | Snappy ground nail (minimal startup/recovery), mutual knockback as spacing tool |
| **Nine Sols** | Combat-first terrain, commitment clarity, telegraph readability (parry deferred) |
| **GDKeys "Anatomy of an Attack"** | Startup → Active → Recovery frame discipline |
| **Game feel / juice** | Hit-stop (2–5 frames), impact clarity, disciplined VFX |
| **2D action platformer movement** | Coyote time, jump buffer, variable jump height, jump cut, asymmetric gravity |
| **Dog protagonist games** | Low silhouette, lunge-bite motion language (not sword slash) |

Refine the numeric targets below if your research suggests better values for a
**combat-action** game (not precision platformer) on **flat Mumbai footpath arenas**.
Document any changes and why.

---

## Game identity (non-negotiable)

**Street Dog** = 2D combat-driven action on a rainy Mumbai metropolitan street block.
Long-term: Nine Sols / Sekiro-adjacent melee + parry. **Today: movement + one ground bite only.**

| Verb | Role |
|------|------|
| **Bite (attack)** | Primary combat action — forward lunge, scrappy street-dog snap |
| **Jump** | Spacing + optional L2 flank tool — NOT the game's core skill check |
| **Move L/R** | Arena positioning on L1 footpath (y≈520) |

**Do NOT implement yet:** parry, dodge roll, combo chain, aerial attack, double jump,
wall jump, dash, enemy AI, health UI, SFX pipeline, sprite sheets.

---

## Current codebase state

### Player (`scenes/player/dog.tscn` + `scripts/player/dog.gd`)

- `CharacterBody2D`, group `"player"`, collision_layer=2, mask=1
- Blockout `Visual` node (ColorRect dog parts including `Snout`)
- Move: constant speed 240, instant direction flip via `Visual.scale.x`
- Jump: floor-only `is_on_floor()`, fixed `jump_velocity=-450`, fall gravity 1.35×
- Camera: look-ahead + drag margins on child `Camera2D`
- **No attack input, no hitbox, no state machine**

### Level (`scenes/levels/street_night.tscn`)

- Mumbai combat blockout: 4 rooms, L1 footpath + 2 optional L2 ledges (y≈456)
- `EnemySpawn_*` Marker2D placeholders exist — **no enemies yet**
- Potholes with `kill_zone.gd` respawn at `Spawn`
- Vertical step L1→L2 ≈ 64px (must be reachable with full hold jump)

### Input map (`project.godot`)

- `move_left`, `move_right`, `jump` — **no `attack` action yet**

---

## Design spec — Jump v1 ("street hop")

Implement **action-platformer forgiveness**, not Celeste-tight precision.

### Required mechanics

1. **Coyote time** — ~0.10–0.12s after leaving floor; jump still counts as grounded
2. **Jump buffer** — ~0.10–0.13s; early jump press queues until landing
3. **Variable jump height** — hold jump = full arc; tap = short hop
4. **Jump cut** — on jump release while `velocity.y < 0`, multiply Y velocity (~0.4–0.5)
5. **Asymmetric gravity** — reduced gravity while rising (~0.6–0.7×); increased while
   falling (~1.4–1.5×); already partially done — unify in one gravity helper
6. **Jump only when allowed** — not during attack recovery (see state machine)

### Tuning targets (starting points — refine in Phase 0)

```
COYOTE_TIME         ≈ 0.11s
JUMP_BUFFER         ≈ 0.12s
JUMP_VELOCITY       ≈ -460 to -480   (must reach L2 at y=456 from L1 y=520)
RISE_GRAVITY_MULT   ≈ 0.65
FALL_GRAVITY_MULT   ≈ 1.45
JUMP_CUT_MULT       ≈ 0.45
GROUND_ACCEL        optional: lerp X velocity for wet-footpath skid feel (~1800/s)
```

### Feel target

- Tap jump = short hop (pothole connectors, combat reposition)
- Hold jump = reach chai stall / bus bench L2 ledge
- No floaty apex hang — this is a street dog, not a floaty metroidvania knight

### Optional blockout juice (low cost)

- Brief `Visual` squash on land (scale tween 0.12s)
- Keep camera look-ahead; don't break existing drag margins

---

## Design spec — Attack v0 ("Street Bite")

### Motion language

**NOT a sword slash.** Forward **lunge bite**: head/snout leads, body follows, quick recoil.
Thematic: scrappy dog on wet Mumbai footpath — short commitment, readable contact.

### Attack phases (frame budget @ 60fps — refine if needed)

```
STARTUP   3 frames   anticipation — lean back, slight squash
ACTIVE    3 frames   hitbox enabled — lunge forward
RECOVERY  9 frames   cannot re-attack; movement restored ~frame 6 of recovery
```

### Hitbox

- `Area2D` child `AttackHitbox` on dog (or under `Visual`)
- `CollisionShape2D` — RectangleShape2D ~48×28px, offset forward in facing direction
- collision_layer = 0 (hitbox doesn't block)
- collision_mask = 4 (`enemies` layer) — also add mask bit for a **test hurtbox** layer
  if you use layer 4 `interactables` temporarily for the placeholder target
- Enable monitoring only during ACTIVE phase
- One hit per swing (track `_hit_targets: Array` or disable after first connect)

### Lunge

- During ACTIVE: apply forward velocity impulse or position nudge (~24–40px total over active)
- Face attack direction = current `Visual.scale.x` sign at press time (lock facing during attack)

### Impact juice (v0)

- **Hit-stop:** 2–3 frames on connect (`Engine.time_scale = 0` then restore via `SceneTreeTimer`
  or frame counter — do NOT pause audio if avoidable)
- **Knockback:** enemy pushed ~100–140 px/s away; dog self-pushback ~30–50 px/s on hit
  (Hollow Knight mutual knockback — creates pothole-edge tension on this level)
- **Whiff:** no hit-stop; full recovery plays

### Movement during attack

- STARTUP: reduced or zero horizontal input (~40% speed)
- ACTIVE: lunge overrides X slightly
- RECOVERY early: no attack input; movement returns mid-recovery
- **Ground only v0** — ignore attack input in air

### Blockout visual (no sprite sheet)

Use existing `Visual` ColorRects:

- STARTUP: `Visual` scale ~(0.92, 0.88) — coiled
- ACTIVE: scale ~(1.15, 0.92), shift `Snout` / `Head` forward ~8–12px
- RECOVERY: tween back to neutral

Optional: brief `modulate` flash on `Snout` during active

### Input

Add to `project.godot`:

```
attack → J and/or K (and optionally mouse button for editor testing)
```

---

## Architecture — implement systematically in this order

### Phase 1 — Input + constants

- Add `attack` to `project.godot` input map
- Create `scripts/player/player_constants.gd` (or `dog_constants.gd`) as `class_name` or
  autoload-free `const` resource — centralize coyote/buffer/attack frame timings
- **Checkpoint:** F5 runs, no behavior change yet

### Phase 2 — Player state machine

Refactor `dog.gd` (or split into `dog_movement.gd` + `dog_attack.gd` if cleaner — keep small).

States (enum):

```
MOVE
ATTACK_STARTUP
ATTACK_ACTIVE
ATTACK_RECOVERY
```

Rules:

- `_physics_process` dispatches by state
- Jump logic only in MOVE (and maybe RECOVERY after movement unlock frame)
- Attack only from MOVE when `is_on_floor()` and coyote not required for attack
- Export key tunables with `@export` for designer iteration

**Checkpoint:** F5 — move/jump still work; attack state transitions with debug print or
visible blockout motion (hitbox can be disabled this phase)

### Phase 3 — Jump v1

- Implement coyote timer, buffer timer, variable height, jump cut, gravity helper
- Verify L2 reach: jump from Room B footpath to chai stall counter (x≈930, y≈456)
- **Checkpoint:** F5 playtest jump checklist (see Acceptance Criteria)

### Phase 4 — Attack hitbox + bite motion

- Add `AttackHitbox` to `dog.tscn`
- Wire ACTIVE phase monitoring + lunge + blockout visual
- **Checkpoint:** F5 — bite animation plays; no target needed yet

### Phase 5 — Placeholder hurtbox (minimal — required to validate combat feel)

Create **one** test target only — do not build full enemy system:

- `scenes/enemies/hurtbox_dummy.tscn`:
  - `StaticBody2D` or `CharacterBody2D` (prefer StaticBody2D for v0)
  - `Area2D` child `Hurtbox` — collision_layer = 3 (`enemies`) or documented layer
  - Group: `"hurtbox"` or `"enemy"`
  - Script `scripts/enemies/hurtbox_dummy.gd`:
    - `take_hit(knockback: Vector2, hit_stop: bool)` — flash `modulate`, apply knockback
    - Simple ColorRect blockout (red-grey rectangle, ~40×50)
- Instance **one** dummy at `RoomMarkers/RoomB/EnemySpawn_1` (x≈835, y≈507) from
  `street_night.gd` `_ready` OR place in `main.tscn` — pick cleanest approach
- Dog `AttackHitbox` connects `area_entered` → call `take_hit` on hurtbox parent

**Checkpoint:** F5 in Room B — bite connects, hit-stop fires, dummy knockback visible

### Phase 6 — Polish pass

- Tune frames/gravity/knockback from Phase 0 research
- Ensure attack doesn't clip through `EdgeWall` or break on potholes
- Remove debug prints
- MCP screenshot of bite connecting in Room B

---

## Files to create / modify

| File | Action |
|------|--------|
| `project.godot` | Add `attack` input |
| `scripts/player/dog.gd` | State machine, jump v1, attack orchestration |
| `scripts/player/player_constants.gd` | Tunable constants (new, optional) |
| `scripts/player/dog_attack.gd` | Attack logic split (new, optional if dog.gd stays readable) |
| `scenes/player/dog.tscn` | `AttackHitbox` Area2D + CollisionShape2D |
| `scenes/enemies/hurtbox_dummy.tscn` | Placeholder target (new) |
| `scripts/enemies/hurtbox_dummy.gd` | `take_hit` + flash (new) |
| `scenes/main.tscn` or `street_night.gd` | Spawn one dummy at Room B |

**Do NOT touch:** level platform layout, `kill_zone.gd` logic, MCP config, Catalyst addon,
parallax/backdrop art, other enemy spawns.

---

## Physics layers (unchanged)

| Layer | Name | Use |
|-------|------|-----|
| 1 | world | Footpath StaticBody2D |
| 2 | player | Dog body |
| 3 | enemies | Hurtbox / future enemies |
| 4 | interactables | unused v0 |

Dog body: layer 2, mask 1.
Attack hitbox: mask includes layer 3.

---

## Scope guardrails

| Do | Don't |
|----|-------|
| One ground bite | Combo system |
| One hurtbox dummy | Enemy AI / patrol |
| Hit-stop 2–3 frames | Screen shake on every hit |
| Export tunables | Hard-code magic numbers only |
| Godot 4 GDScript | Godot 3 syntax (`yield`, `setget`) |
| `move_and_slide()` | `move_and_collide()` for player |
| Small focused scripts | 400-line god script |

---

## Acceptance criteria (all must pass)

### Jump

1. Coyote: walk off L1 edge, jump within ~0.1s → still jumps
2. Buffer: press jump before landing → jumps on touchdown
3. Tap jump < hold jump height (variable height works)
4. Release mid-rise → arc cuts short (jump cut)
5. Can reach L2 chai counter from Room B footpath with full hold jump
6. Cannot jump during attack startup/active

### Attack

7. `J`/`K` triggers bite on ground only
8. Hitbox active only during ACTIVE phase (3 frames) — no phantom hits
9. Whiff plays full recovery; no hit-stop on whiff
10. Hit on dummy: hit-stop ~2–3 frames + dummy knockback + dog self-pushback
11. One bite per swing (no multi-hit same target same swing)
12. Facing locked during attack — no instant flip mid-lunge

### Integration

13. F5 zero errors in Output
14. Move → jump → bite → recovery → move feels continuous in Room B
15. Existing pothole respawn still works

---

## Deliverable format

When done, report:

1. **Feel targets** (from Phase 0 research, 5–10 bullets)
2. **Final tuning table** — all constants with values you chose and why
3. **State machine diagram** (ascii or bullet transitions)
4. **Frame data table** — startup / active / recovery frames
5. **Files changed** — list with one-line summary each
6. **F5 test script** — step-by-step for human playtest (Room A → B, jump L2, bite dummy)
7. **Known limitations** — what v1 intentionally omits (parry, air attack, etc.)
8. **Suggested next step** — one sentence (e.g. "add second dummy + HP bar")

---

## Implementation notes (Godot 4 specifics)

- Use `_physics_process(delta)` for movement; track coyote/buffer as `float` timers decremented by `delta`
- `is_on_floor()` resets coyote timer; `Input.is_action_just_pressed("jump")` resets buffer timer
- Hit-stop pattern:

  ```gdscript
  Engine.time_scale = 0.0
  await get_tree().create_timer(duration, true, false, true).timeout  # process_always=true
  Engine.time_scale = 1.0
  ```

  Or use a frame counter in `_physics_process` if async complicates attack state — pick one approach, stay consistent.

- `Area2D` monitoring: set `monitoring = false` by default; enable only in ACTIVE
- Connect `area_entered` once in `_ready`; filter by group `"hurtbox"` or `"enemy"`
- Keep `Visual` blockout tweens simple — `create_tween()` on attack phase enter

Work **phase by phase**. Do not skip to Phase 5 before jump feels right in Phase 3.
