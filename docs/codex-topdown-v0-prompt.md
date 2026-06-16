# Codex Task: Top-Down Mumbai Gully Combat v0

Copy the **paste block** at the bottom into a new Codex thread. Godot editor must be open with Godot Catalyst **Connected**.

**Design context:** Parallel prototype to the existing **side-view** Mumbai street build. Do not delete or break side-view scenes on `main`. Work on branch `topdown-prototype`.

---

## Task: Build top-down Street Dog combat prototype v0

Read `street-dog-draft/AGENTS.md` and `README.md` first.
Godot 4.6 · 2D only · GL Compatibility · GDScript only.

**Before coding:**
1. Create and checkout git branch `topdown-prototype` from `main`.
2. Use Godot Catalyst MCP to inspect the repo; **never invent node paths**.
3. Run F5 after each phase; fix errors before proceeding.
4. **Do not modify** side-view entry (`scenes/main.tscn` → `street_night` + side-view `dog`) on `main`.
   On this branch, point `run/main_scene` to the new top-down entry scene.

---

## Phase 0 — Research pass (brief, document in deliverable)

Synthesize a **5–10 bullet "feel target"** note. Prioritize:

| Source family | What to extract |
|---------------|-----------------|
| **Hades / 8-way top-down** | Normalized diagonal speed, face-movement-direction, snappy accel |
| **Hotline Miami** (spirit only) | Room-as-floor-plan, lethal clarity, fast retry — **not** masks/guns/scoring |
| **Nuclear Throne** | Top-down crowd readability, threat at range |
| **GDQuest / Godot docs** | `Input.get_vector`, `CharacterBody2D` floating mode, `move_and_slide` |
| **Side-view Street Dog R&D** | Lunge-bite language, hit-stop, knockback — adapt to **360° aim via move dir** |
| **Canine movement** | Scrappy stray: fast turns, short commits, not floaty human strafe |

Refine default constants below if research suggests better industry-standard starting points.
**All numbers must remain `@export` tunable** after implementation.

---

## Game identity (v0 — non-negotiable)

**Street Dog (top-down)** = rainy **night Mumbai gully** arena. Player is a **scrappy stray**. Threats are **rival dogs only** (2 in arena).

| Verb | Role |
|------|------|
| **Move (8-way)** | Primary positioning — sprite faces movement direction |
| **Bite (attack)** | Forward **lunge** in last movement direction (or current input dir if stationary) |
| **Take damage** | 3 HP player; enemies hit harder than grunts |

| Explicitly **NOT in v0** | Deferred |
|--------------------------|----------|
| Dash, parry, jump | v0.2+ |
| Swarm / pack followers | v1 |
| Pack flank AI roles (driver/flanker) | v0.2 |
| Humans, ranged projectiles, hazards | later |
| Sprite sheets | rectangle blockout only |
| Side-view scene changes | never on this branch's parallel paths |

### Success bar (30-second playtest)

Human must feel within 30s:
1. **Bite has weight** — lunge, hit-stop, knockback
2. **Arena reads as Mumbai gully** — not generic grey box
3. **Movement feels doglike** — scrappy, quick, not ice-skating

---

## Architecture — branch & file layout

### Git

```bash
git checkout main
git pull
git checkout -b topdown-prototype
```

Commit in logical chunks on this branch only. Do not merge to `main` unless human asks.

### Namespace (parallel fork — do not overwrite side-view)

| Path | Purpose |
|------|---------|
| `scenes/topdown/main_topdown.tscn` | Entry: arena + player + HUD |
| `scenes/topdown/arena_mumbai_gully.tscn` | Single combat room |
| `scenes/topdown/player_dog_topdown.tscn` | Top-down player |
| `scenes/topdown/rival_dog.tscn` | Enemy |
| `scenes/topdown/player_hud_topdown.tscn` | HP bar |
| `scripts/topdown/topdown_tuning.gd` | `class_name TopdownTuning` — default constants |
| `scripts/topdown/player_dog_topdown.gd` | Movement + bite state machine |
| `scripts/topdown/rival_dog.gd` | Simple chase + telegraphed bite |
| `scripts/topdown/arena_mumbai_gully.gd` | Room build + spawns |
| `scripts/topdown/player_health_topdown.gd` | HP component (or reuse pattern from side-view) |

On branch `topdown-prototype`, set:

```
run/main_scene = res://scenes/topdown/main_topdown.tscn
```

**Leave** `scenes/main.tscn`, `scenes/player/dog.tscn`, `scenes/levels/street_night.tscn` **untouched** (still in repo for comparison).

---

## Tunable constants — industry-standard defaults

Centralize in `scripts/topdown/topdown_tuning.gd` as `extends Resource` with `class_name TopdownTuning` **or** as `const` + `@export` mirrors on nodes. Every value below must be overridable in the Inspector (`@export_group` recommended).

### Player movement (8-way, scrappy stray)

Industry refs: Hades ~200–275 px/s; fast indie top-down ~280–320; accel ~1500–2200 px/s².

```
MOVE_SPEED              = 290.0     # px/s — scrappy stray baseline
MOVE_ACCEL              = 2000.0    # px/s² — reach target speed quickly
MOVE_FRICTION           = 2400.0    # px/s² — stop when input released (doglike scrabble)
INPUT_DEADZONE          = 0.2       # match project input deadzone
ROTATION_LERP_SPEED     = 18.0      # visual face move dir (radians/sec equivalent feel)
ALLOW_DIAGONAL          = true      # normalize vector (industry standard)
```

`CharacterBody2D` → Motion Mode: **Floating** (top-down; not platformer floor snap).

### Player bite — forward lunge (GDKeys frame model @ 60fps)

Industry fast melee: startup 2–4f, active 2–4f, recovery 8–12f.

```
ATTACK_STARTUP_FRAMES       = 3
ATTACK_ACTIVE_FRAMES        = 3
ATTACK_RECOVERY_FRAMES      = 10
ATTACK_RECOVERY_MOVE_UNLOCK = 6     # frame of recovery when move input returns
ATTACK_STARTUP_SPEED_MULT   = 0.35  # slow during wind-up
ATTACK_LUNGE_SPEED          = 520.0  # px/s during active (forward = bite dir)
ATTACK_HITBOX_OFFSET         = 28.0  # px from body center in bite direction
ATTACK_HITBOX_SIZE           = Vector2(44, 36)
ATTACK_KNOCKBACK_TARGET      = 130.0 # px/s on enemy
ATTACK_SELF_KNOCKBACK        = 45.0  # px/s on player after connect
ATTACK_HIT_STOP_SEC          = 0.045 # ~2.7 frames @ 60 — industry juice range 0.04–0.06
ATTACK_COOLDOWN_ON_WHiff     = full recovery
```

Bite direction: **last non-zero move direction**; if stationary, use current input vector; if still zero, use current visual facing.

**Ground only** — N/A for top-down floating; bite allowed whenever not in recovery (no air state v0).

### Player health

```
PLAYER_MAX_HP           = 3
PLAYER_INVULN_SEC       = 0.85    # after hit — industry i-frame band 0.6–1.0s
PLAYER_HITSTUN_FRAMES     = 12
RESPAWN_FULL_HP         = true    # training mode — respawn at Spawn marker
RESPAWN_FADE_SEC        = 0.35
```

### Rival dog enemy (×2 in arena, simple AI v0)

```
RIVAL_MOVE_SPEED        = 175.0    # slower than player — player kites
RIVAL_DETECTION_RANGE   = 220.0    # px — aggro radius
RIVAL_ATTACK_RANGE      = 42.0     # px — starts windup
RIVAL_WINDUP_FRAMES     = 20       # telegraph — readable in top-down
RIVAL_ATTACK_FRAMES     = 4
RIVAL_RECOVER_FRAMES    = 18
RIVAL_MAX_HP_GRUNT      = 2        # dies in 2 bites if 1 dmg/hit
RIVAL_MAX_HP_BULLY      = 3        # second enemy slightly tankier
RIVAL_CONTACT_DAMAGE    = 1
RIVAL_BITE_KNOCKBACK    = 160.0    # px/s to player on hit
```

AI v0 (**no pack roles**): idle/patrol small radius → chase if player in detection → windup → bite → recover. Two enemies should **pinch** player if careless but need not coordinate roles yet.

### Arena — Mumbai gully choke (single room)

```
ARENA_WIDTH             = 960.0    # px — readable on 1280 viewport
ARENA_HEIGHT            = 720.0
FOOTPATH_COLOR          = wet dark brown-grey (document Color values)
WALL_INSET              = 32.0     # collision boundary from visual edge
SPAWN_PLAYER            = Vector2(120, 360)
SPAWN_RIVAL_A           = Vector2(720, 280)
SPAWN_RIVAL_B           = Vector2(780, 480)
```

Dressing (ColorRect blockout — **Mumbai identity required**):
- Narrow **gully** walls (chawl wall, corrugated stall lip)
- Wet **footpath** center band
- **Chai stall** amber counter chunk (top-left or top-center)
- **Puddle** sheen (dark blue-grey, non-lethal v0 — visual only OR slow zone @export toggle default off)
- Optional **BEST-green** bus-stop stripe accent — one rect is enough

Reference tone from existing `street_night.gd` palette — MCP-read it for color inspiration; do not copy side-view layout wholesale.

---

## Input map (add on branch — do not break side-view actions on merge)

Add to `project.godot`:

```
move_up    → W, Up arrow
move_down  → S, Down arrow
move_left  → A, Left arrow   (already exists — keep)
move_right → D, Right arrow  (already exists — keep)
attack     → J, K            (already exists — keep)
```

Player reads movement via:

```gdscript
var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
```

---

## Physics layers (unchanged)

| Layer | Name | Use |
|-------|------|-----|
| 1 | world | Walls, stall colliders |
| 2 | player | Player body |
| 3 | enemies | Rival dog bodies + hurtboxes |
| 4 | interactables | unused v0 |

- Player body: layer 2, mask 1 | 4 (world + enemies block)
- Player attack hitbox: mask layer 3
- Rival hurtbox: layer 3, group `"hurtbox"`
- Rival attack hitbox: mask layer 2
- Use `set_deferred("monitoring", ...)` when toggling hitboxes inside signal callbacks

---

## Player state machine

```
MOVE
ATTACK_STARTUP
ATTACK_ACTIVE
ATTACK_RECOVERY
HITSTUN
```

Rules:
- Attack from `MOVE` only (not during HITSTUN)
- Movement in recovery after `ATTACK_RECOVERY_MOVE_UNLOCK`
- `receive_enemy_hit(damage, knockback, attacker)` on player — respect invuln
- On death (`HP <= 0`): fade → respawn at arena `Spawn` with full HP

### Visual blockout (no sprites)

`ColorRect` dog — brown/tan body, darker snout wedge. On move: lerp rotation to `direction.angle()`.
On bite: squash/stretch tween on startup/active/recovery (reuse side-view language adapted to rotation).

---

## Rival dog scene

`CharacterBody2D` + rectangle blockout (grey/black stray — visually distinct from player).
**Telegraph** during windup: yellow `ColorRect` bar above body (Hotline-readable).
`take_hit(knockback, hit_stop)` — flash, stagger, HP pip or modulate.
On death: fade + `queue_free()` or disable collider.

---

## Implementation phases (systematic — do not skip)

### Phase 1 — Branch + tuning resource + input

- Create branch `topdown-prototype`
- Add `topdown_tuning.gd` with all defaults as `@export` or documented consts
- Add `move_up` / `move_down` inputs
- Set `run/main_scene` to top-down entry
- **Checkpoint:** F5 loads empty/main stub without errors

### Phase 2 — Arena blockout

- `arena_mumbai_gully.tscn` + script: static walls, footpath, Mumbai dressing, `Spawn` + `RivalSpawn_A/B` markers
- **Checkpoint:** F5 shows arena; player placeholder can stand on footpath

### Phase 3 — Player movement (8-way)

- `player_dog_topdown.tscn` + script: floating `CharacterBody2D`, normalized 8-way, face move dir, friction
- All movement fields `@export` with tuning defaults
- **Checkpoint:** WASD feels scrappy; diagonals not faster than cardinals

### Phase 4 — Player bite

- Attack state machine, `AttackHitbox` Area2D, lunge in bite direction, hit-stop, self-knockback
- **Checkpoint:** bite whiff + recovery works with no enemies

### Phase 5 — Rival dogs (×2)

- `rival_dog.tscn` + simple AI + `take_hit` + telegraphed bite damages player
- Spawn both rivals from arena script
- **Checkpoint:** 2-dog pinch possible; player 3 HP; death respawns full HP at Spawn

### Phase 6 — HUD + polish

- Minimal HP bar (`CanvasLayer`)
- Wire `GameSfx` if autoload exists (optional tones); use `GameSfxScript` preload pattern if LSP needed
- Remove debug prints; MCP screenshot of arena with 2 rivals
- **Checkpoint:** all acceptance criteria pass

---

## Scope guardrails

| Do | Don't |
|----|-------|
| `@export` every tunable | Magic numbers only in code |
| `scenes/topdown/*` namespace | Overwrite `scenes/player/dog.tscn` |
| Rectangle blockout | Sprite sheets / asset store purchases |
| 2 rival dogs, simple AI | Pack flank roles, swarm |
| `set_deferred` for hitbox monitoring in signals | Toggle monitoring inside `body_entered` |
| Godot 4 GDScript | Godot 3 syntax |
| Phase checkpoints + F5 | One-shot 2000-line script |

---

## Acceptance criteria (all must pass)

### Movement
1. 8-way WASD + arrows; diagonal speed normalized
2. Sprite/visual faces movement direction smoothly
3. Release keys → friction stop (not instant ice slide)
4. Collision with arena walls — no clipping

### Bite
5. `J`/`K` triggers lunge bite in facing/move direction
6. Hitbox active only during ACTIVE phase
7. Hit-stop on connect (~0.04–0.06s tunable); no hit-stop on whiff
8. One hit per target per swing
9. Enemy knockback + player self-pushback on connect

### Enemies
10. Exactly **2** rival dogs in arena
11. Windup telegraph visible before enemy bite
12. Enemy bite damages player; player invuln after hit
13. Player dies at 0 HP → respawn at Spawn with **full HP**

### Integration
14. F5 zero errors in Output
15. Arena reads as **Mumbai gully** (not generic) — at least 3 distinct dressing elements
16. Side-view `scenes/main.tscn` still present and unbroken in repo (human can switch main scene back to test)

---

## Deliverable format

When done, report:

1. **Feel targets** (Phase 0, 5–10 bullets)
2. **Tuning table** — every `@export` with final default and Inspector path
3. **State machine** — player + rival (ascii or bullets)
4. **Frame data** — bite phases, enemy windup/attack/recover
5. **Files created** — table with one-line summary
6. **F5 test script** — 60-second human playtest steps
7. **Known limitations** — swarm, parry, dash, pack AI, etc.
8. **Suggested feel-test knobs** — top 5 exports human should tweak first after playtest

---

## Godot 4 implementation notes

- Top-down body: `CharacterBody2D.motion_mode = MOTION_MODE_FLOATING`
- Movement:

  ```gdscript
  var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
  if direction.length() > 1.0:
      direction = direction.normalized()
  velocity = velocity.move_toward(direction * move_speed, move_accel * delta)
  if direction == Vector2.ZERO:
      velocity = velocity.move_toward(Vector2.ZERO, move_friction * delta)
  ```

- Face direction: `visual.rotation = lerp_angle(visual.rotation, direction.angle(), rotation_lerp * delta)` when `direction.length() > 0.1`
- Hit-stop: `await get_tree().create_timer(attack_hit_stop_sec, true, false, true).timeout` with `Engine.time_scale = 0`
- Attack direction locked at bite press from `direction` or `_last_move_direction`

Work **phase by phase**. Tune defaults to industry standards; human will iterate feel in Inspector after playtest.

---

## Paste block (for Codex)

```
You are working on Street Dog — Godot 4.6 2D at:
/Users/aman.shrivastava/Documents/personal/projects/street-dog-draft

Read AGENTS.md and the full task spec:
docs/codex-topdown-v0-prompt.md

Godot editor open · Godot Catalyst MCP Connected (port 6505).

Implement the top-down Mumbai gully combat prototype v0 exactly as specified in that doc:
- Git branch: topdown-prototype (create from main)
- Parallel namespace: scenes/topdown/, scripts/topdown/
- Do NOT break side-view scenes (main.tscn, dog.tscn, street_night.tscn)
- 1 Mumbai arena, 8-way scrappy dog, forward-lunge bite, 3 HP, 2 rival dogs, rectangle blockout
- NO dash, parry, jump, swarm, humans, or pack AI in v0
- ALL combat/movement values @export tunable with industry-standard defaults in topdown_tuning.gd

Work phase by phase (1→6). F5 after each phase. Fix all errors before continuing.
When done, output the deliverable format from the doc.
```
