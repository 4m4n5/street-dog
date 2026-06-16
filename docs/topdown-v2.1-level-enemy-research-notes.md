# Topdown v2.1 Level + Enemy Research Notes

Date: 2026-06-16
Task: Chawl Fork arena redesign, four rival dogs, rival bite parity, room-clear loop.

## Source Availability

- `gamineai` telegraph/color timing sources requested in the task spec could not be discovered through web search or fetched directly on 2026-06-16. The timing/color rules below preserve the locked spec bands and are backed by accessible combat-readability sources.
- `recited.io` attack-pattern source returned a fetch cache miss on 2026-06-16. The rival FSM still follows the locked startup/active/recovery spec and is backed by post-attack vulnerability and existing player attack implementation patterns.

## Cited Research Bullets

- Hotline-style clarity depends on every enemy serving a purpose, readable solids, and enemies standing out from the floor; avoid dark rivals on dark floors and invisible blockers. URL: https://steamcommunity.com/sharedfiles/filedetails/?id=3305685660
- The door-problem article frames encounter geometry as map control: players retreat when the entry edge gives safer angles than the arena. Add a strong internal foothold so the best first move is forward, not backward. URL: https://www.gamedeveloper.com/design/the-door-problem-of-combat-design
- The same door-problem source recommends hidden information and AI leashing to divide an arena into layers; for Street Dog this maps to spawn cover, a sentry leash at the fork, and no single viewpoint that reveals all four rivals. URL: https://www.gamedeveloper.com/design/the-door-problem-of-combat-design
- Chokes should be manually crafted with architecture, cover, timing, and limited entrances; Street Dog should use one narrow commit choke and one wider flank choke rather than a uniform corridor. URL: https://www.worldofleveldesign.com/categories/csgo-tutorials/csgo-principles-choke-point-level-design.php
- Loops give players positional choice, while too many paths become unpredictable "guess maps"; Chawl Fork should have two reliable routes through the middle, not a maze. URL: https://critpoints.net/category/level-design/
- Hades room kits use full cover, half cover, traps, pillars, tables, urns, exits, and spawn points as authored gameplay parts; Street Dog props should be collision/verb objects, not dressing only. URL: https://threadreaderapp.com/thread/1311777010239193088.html
- Hades biome rules tie layout to enemy design; Asphodel enemies needed traversal behavior that fit magma islands. For Street Dog, rival roles should match their pockets: sentry leashed at choke, racer in side loop, bully pressuring bus alcove. URL: https://kotaku.com/hades-level-design-is-less-random-than-it-seems-1845254545
- Post-attack vulnerability is a second telegraph: after an enemy asks "can you avoid my attack?", it must also show "how can you defeat me?" Use recovery as an obvious punish window. URL: https://www.chaoticstupid.com/telegraphs-2-post-attack-vulnerability/
- A useful post-attack window can sit around 0.25s to 1.0s depending on enemy and surrounding chaos; for v2.1, bully/sentry recoveries should be longer than player recovery, while racer stays punishable but brief. URL: https://www.chaoticstupid.com/telegraphs-2-post-attack-vulnerability/
- Enter the Gungeon's team hand-designed and repeatedly playtested rooms before procedural assembly; this supports Chawl Fork as a single authored screen with measured pockets and spawn tables. URL: https://www.gamedeveloper.com/design/q-a-the-guns-and-dungeons-of-i-enter-the-gungeon-i-
- Gungeon environmental verbs make the place of the fight matter: tables, barrels, chandeliers, coffins, and carts are combat affordances. For this pass, the chair should slide into rivals for stagger only, keeping prop damage out of scope. URL: https://www.gamedeveloper.com/design/q-a-the-guns-and-dungeons-of-i-enter-the-gungeon-i-
- Chawl identity comes from dense narrow lanes, shared corridors, balconies, covered walkways, sloped monsoon-aware roofs, ground-floor storefronts, and daily life spilling into semi-public zones. Use loggia, laundry-line poles, chai counter, corrugated shop lip, sodium pools, and wet pavers. URL: https://architizer.com/blog/inspiration/stories/mumbais-chawls-indias-housing-could-soon-disappear/
- Godot `CharacterBody2D.move_and_slide()` is suited to top-down movement, and `MOTION_MODE_FLOATING` treats collisions as walls. Rival lunge parity should keep `CharacterBody2D` with floating motion. URL: https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html
- Godot custom `Resource` scripts serialize to `.tres` and are Inspector-editable, matching `BiteAttackProfile` and `RivalArchetype` as tunable data rather than hard-coded globals. URL: https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html
- Top-down readability depends on seeing the character from above, with small but distinct silhouettes, shadows, and details that support collision prediction. Rival archetypes should differ by shoulder scale and palette at a glance. URL: https://www.sandromaglione.com/articles/pixel-art-top-down-game-sprite-design-and-animation
- Unit art should read role/threat in about 0.5s through silhouette, color, and reduced detail. Stray, Sentry, Racer, and Bully need visible role differences even before motion begins. URL: https://vsquad.art/blog/2d-unit-art-for-games-styles-and-production-process
- Combat juice should be chosen from the target emotion; Street Dog targets precision/scrappy physicality, so use short hit-stop, crisp SFX, and restrained dust rather than heavy screen shake. URL: https://gamejuice.co.uk/articles/juice-intention-matrix
- Input buffering and hit-stop preserve perceived intent and impact; keep player preset B values untouched and make rival hit-stop lighter than player connect hit-stop. URL: https://kindatechnical.com/game-development/input-buffering-coyote-time-and-game-feel.html
- Accessibility guidance warns against rapid flashes, large repeated patterns, and intense red flicker; enemy telegraph wedges should be readable via hue/shape/alpha without strobing or full-screen effects. URL: https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/

## Layout + Combat Targets

- Arena readable in under 3 seconds: spawn foothold, fork, courtyard well, side loop, and bus alcove visible as separate shapes.
- Keep a high-cover spawn foothold at approximately `x=110..260, y=420..580`; player cannot see all four rivals from spawn.
- Use at least two routes between center and bus side: main wet lane via fork and lower/rear side loop.
- Use one narrow commit choke of 56-72 px at the spawn-to-fork threshold and one wider flank choke of 88-110 px on the lower loop.
- Put cover islands 80-140 px apart so lunges commit around cover instead of trapping movement.
- Place Sentry on a short leash at the fork/main choke; it should not chase back to the spawn foothold.
- Place Racer in the side loop with a skirmish role: shorter telegraph, faster lunge, and lateral pressure.
- Place Bully in the BEST/bus alcove: heavier body, 3 HP, longer recovery, heavier knockback.
- Place Stray in courtyard well as the teaching rival: patrols first, 2 HP, near-player bite parity.
- Rival attack telegraph is a forward wedge in enemy amber/red lane, never a bar above the head.
- Rival bite direction locks at windup start; active state is a lunge, not contact damage.
- Telegraph timing ladder at 60 fps: Racer 2f startup, Stray 3f, Bully 4f, Sentry 5f; recoveries 10/12/16/14f respectively for punish windows.
- Use post-attack vulnerability explicitly: recover state cannot immediately re-chase on bite-range contact.
- Chair collision into a rival applies 6-10f stagger with zero HP damage.
- Soft clear: living rival count reaches zero, show lowercase `gully clear` for about 1.5s, then respawn all four rivals after 2s without changing player HP.
