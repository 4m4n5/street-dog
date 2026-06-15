# Top-Down Attack Feel v2 Research Notes

Date: 2026-06-15

Scope: attack feel only for Street Dog top-down prototype. No level redesign,
prop-kill implementation, dash, parry, room-clear state, side-view scene
changes, or runtime style switcher.

Human defaults used:

- Q1 steering during lunge: A - Hades-style commit; no steering during active
  lunge, with movement unlocked from `attack_recovery_move_unlock`.
- Q2 whiff feedback: A - subtle whiff package; procedural snort/grunt plus a
  tiny forward dust puff, with no hit-stop or camera punch.
- Q3 git: B - logical commits on `topdown-prototype`, no push.

## Cited Research Bullets

- Hades room design is authored around biome-specific principles and escalating
  chamber scale, so Street Dog should treat "Hades-inspired" as a commitment to
  readable encounter pacing and deliberate attack beats, not random chaos.
  Source: https://kotaku.com/hades-level-design-is-less-random-than-it-seems-1845254545

- Supergiant's Hades design examples connect room constraints with enemy
  mobility; for this pass, bite lunge should stay direction-committed so rival
  spacing and punish windows remain legible. Source:
  https://kotaku.com/hades-level-design-is-less-random-than-it-seems-1845254545

- Input buffering should store player intent for a short window and execute
  once the action becomes available; a common action-game/fighting-game band is
  about 80-150 ms, roughly 5-9 frames at 60 fps. Source:
  https://kindatechnical.com/game-development/input-buffering-coyote-time-and-game-feel.html

- Coyote time is an intent-preserving grace window. For top-down bite, the
  analog is not "ground after ledge"; it is preserving last facing for a few
  frames after movement input stops so a released-stick bite still points where
  the player meant. Source:
  https://kindatechnical.com/game-development/input-buffering-coyote-time-and-game-feel.html

- Hit-stop should be connect-only for this pass: light attacks usually live
  around 30-50 ms, heavier hits around 60-100 ms. Street Dog's bite can lean
  toward 50-60 ms without becoming a kill-tier freeze. Source:
  https://kindatechnical.com/game-development/input-buffering-coyote-time-and-game-feel.html

- The juice target should be precision and scrappy impact, not spectacle.
  Short hit-stop, small particles, and crisp sound support readability; heavy
  shake and broad particle bursts would obscure the top-down brawl. Source:
  https://gamejuice.co.uk/articles/juice-intention-matrix

- Game feel work splits into physical tuning, amplification/juice, and
  streamlining; v2 should touch all three narrowly: frame data/knockback,
  subtle feedback, and buffer/coyote input support. Source:
  https://arxiv.org/abs/2011.09201

- Top-down encounter difficulty is shaped by movement and cover geometry, but
  this pass should not change layout. Attack readability has to work inside the
  current three-pocket layout instead of depending on new walls or props.
  Source: https://www.gamedeveloper.com/design/how-an-environment-layout-affects-difficulty

- Top-down sprites read from above and benefit from clear facing, shadows, and
  small particles. A forward wedge on the snout and directional dust are
  appropriate blockout-level readability aids. Source:
  https://www.sandromaglione.com/articles/pixel-art-top-down-game-sprite-design-and-animation

- Unit readability should resolve in about half a second through silhouette,
  color, and low-detail clarity. The bite windup and hit flash should be simple
  high-contrast shapes, not dense sprite animation. Source:
  https://vsquad.art/blog/2d-unit-art-for-games-styles-and-production-process

- Godot `CharacterBody2D.MOTION_MODE_FLOATING` is the correct top-down motion
  mode because there is no floor/ceiling distinction and slide speed remains
  constant. Source:
  https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html

- Godot `Engine.time_scale` affects timers, scene-tree timers, and process
  delta; hit-stop recovery must therefore use `SceneTree.create_timer(...,
  ignore_time_scale=true)`. Sources:
  https://docs.godotengine.org/en/stable/classes/class_engine.html and
  https://docs.godotengine.org/en/stable/classes/class_scenetree.html

- Accessibility guidance warns against large flicker and repeated high-contrast
  visual patterns; Street Dog v2 therefore keeps flash localized to player
  snout/target feedback and uses a 3 px camera nudge only on confirmed hits.
  Source:
  https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/

- Enter the Gungeon uses environment interaction to make the combat place
  matter, but that belongs in v2.1+ for Street Dog. This pass only documents
  Gungeon-leaning prop synergy as a future direction. Source:
  https://www.gamedeveloper.com/design/q-a-the-guns-and-dungeons-of-i-enter-the-gungeon-i-

## Phase 0 Feel Targets

- Ship Hades-leaning commit: bite active frames are locked to the press/facing
  direction, with full 8-way movement unlocked from recovery frame 6.
- Hit-stop happens only on rival connect, not on whiff and not on prop graze.
- Default buffer is 8 frames at 60 fps: enough to catch late recovery presses
  without turning bite into an auto-chain.
- Recovery buffer is 4 frames: late recovery attack presses should enter the
  next startup immediately when recovery ends.
- Coyote bite is 6 frames: releasing movement then biting keeps last facing
  briefly, and buffered attacks store the direction at press time.
- One bite per lunge: no buffering during startup/active, avoiding accidental
  double-tap chains while committed.
- Whiff feedback stays light: procedural whiff sound plus tiny dust, no camera
  nudge, no hit-stop, no extra recovery under default Q2=A.
- Connect feedback is one tier higher than whiff: player/rival flash, small
  directional dust, tiny camera nudge, and synced rival stagger.
- Stagger should start on the same frame as player hit-stop; for a 0.055 sec
  stop at 60 fps, the synced baseline is about 4 stagger frames.
- Side-view scenes remain untouched; all implementation stays in
  `scripts/topdown/`, `resources/topdown/`, `scripts/audio/game_sfx.gd`, and
  docs.

## Benchmark Presets

| Preset | Intent | Startup | Active | Recovery | Unlock | Lunge | Hit-stop | Target KB | Self KB |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| A - Current | Baseline v1 | 3f | 3f | 10f | 6f | 520 | 0.045s | 130 | 45 |
| B - Hades-leaning | Ship: snappier commit, stronger connect | 2f | 3f | 10f | 6f | 540 | 0.055s | 160 | 48 |
| C - Hotline-leaning | Doc only: faster, thinner punish beat | 1f | 2f | 7f | 5f | 600 | 0.035s | 115 | 35 |

Preset B rationale: keep total bite length familiar at 15 frames, shorten
startup by 1 frame, preserve 3 active frames for diagonal choke reliability,
raise connect stop and knockback enough to read without kill-tier shake.

## Buffer State Diagram

```text
MOVE --attack press--> ATTACK_STARTUP -> ATTACK_ACTIVE -> ATTACK_RECOVERY -> MOVE
                                ^                              |
                                |                              |
                                +-- buffered attack at recovery end

ATTACK_RECOVERY --attack press--> store 1 buffered bite + direction at press
ATTACK_STARTUP/ACTIVE --attack press--> ignored to prevent accidental chains
HITSTUN --attack press--> ignored; no auto-counter after taking damage
MOVE no input --6 frames--> bite may still use last move/facing direction
```

## Alternate Styles - Documentation Only

| Style | Frame philosophy | Juice | When to try |
|---|---|---|---|
| Hotline-leaning | Near-zero startup, short recovery, lethal commitment | Minimal stop, strong restart loop | Next human round if the sandbox should become sharper and more brittle |
| Nuclear Throne-leaning | Higher knockback, longer stagger, more screen impulse | More knockback VFX and chunkier audio | Next human round if bite should feel more explosive and chaotic |
| Gungeon-leaning | Bite routes into prop reactions and cover affordances | Clang, prop motion, alert radius | v2.1 level/prop pass, not attack-feel v2 |

## Phase Validation Log

- Phase 0 F5: main scene launched through Catalyst; console output clean.
- Phase 1 F5: preset B tuning launched through Catalyst; console output clean.
- Phase 2 F5: recovery buffer/coyote implementation launched through Catalyst; console output clean.
- Phase 3 F5: whiff feedback path launched and exercised through Catalyst; console output clean.
- Phase 4 F5: rival stagger sync launched through Catalyst; console output clean.
- Phase 5 F5: procedural whiff SFX launched and exercised through Catalyst; console output clean.
- Phase 6 F5: final docs/KB/log pass launched through Catalyst; console output clean.
