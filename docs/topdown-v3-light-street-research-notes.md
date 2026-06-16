# Topdown v3 Light Street Research Notes

Date: 2026-06-16
Slice: Gully Segment 01, 1920x1080, two sodium poles plus one chai spill.

## Cited Findings

- Light should be a design pass, not a polish pass: place global darkness first, then wayfinding lights, then combat lights, then mood details. For v3 this means `CanvasModulate`, `LAMP_A`, `LAMP_B`, then chai spill and wet decals. Source: [Level Design Book - Lighting](https://book.leveldesignbook.com/process/lighting)
- Motivated fixtures matter because unmotivated light feels arbitrary. Every `PointLight2D` in this slice gets a visible pole/fixture, while chai spill stays a painted doorway wash. Source: [Level Design Book - Lighting](https://book.leveldesignbook.com/process/lighting)
- Ref4's strongest usable lesson is circular amber pools separated by darker road, so the two poles should be distinct nodes with a shadow gap between them rather than a continuous glowing lane. Source: [ref4](../references/level1/ref4.jpeg)
- Ref3 supports a dark arterial canyon: the main run is readable because building masses stay dark on both sides, not because walls outline rooms. Source: [ref3](../references/level1/ref3.jpeg)
- Ref1/ref2 support the single side gully: irregular cuts and shop spill can add Mumbai street texture, but the v3 palette must stay sodium/chai rather than cyan-magenta cyberpunk. Sources: [ref1](../references/level1/ref1.jpeg), [ref2](../references/level1/ref2.jpeg)
- Godot's `CanvasModulate` is the correct base-night tool because it tints the canvas globally; this slice uses it for dark blue-grey ambience before local lights. Source: [Godot CanvasModulate docs](https://docs.godotengine.org/en/stable/classes/class_canvasmodulate.html)
- Godot `PointLight2D` uses a texture to define light shape, so the top-down lamp prop should generate a radial `GradientTexture2D` rather than rely on a rectangular alpha slice. Source: [Godot PointLight2D docs](https://docs.godotengine.org/en/stable/classes/class_pointlight2d.html)
- `LightOccluder2D` requires an occluder polygon and casts shadows from `Light2D`; facade shoulders should get occluder polygons so amber pools do not bleed through buildings. Source: [Godot LightOccluder2D docs](https://docs.godotengine.org/en/stable/classes/class_lightoccluder2d.html)
- A top-down 2D night scene can be built by darkening the scene, adding `PointLight2D`, and enabling shadows once occluders exist; this matches the v3 hybrid pipeline. Source: [Catlike Coding - True Top-Down 2D Light and Shadow](https://catlikecoding.com/godot/true-top-down-2d/4-light-and-shadow/)
- The "door problem" warns that players retreat to safe choke edges if the fight starts in a doorway. Here the player foothold is the chai spill, while rivals start dark and emerge into lamp pools so the fight is invited forward. Source: [Game Developer - The Door Problem of Combat Design](https://www.gamedeveloper.com/design/the-door-problem-of-combat-design)
- Props should create flow, pacing, and choice; place the chair and sacks at lamp-pool edges so they are readable affordances, not background clutter. Source: [World of Level Design - Cover Object Placement](https://worldofleveldesign.com/categories/level_design_tutorials/cover-object-placement-for-level-design.php)
- Hand-authored room/pocket kits are fairer than purely generated shapes in high-speed top-down action; the single wave should use authored spawn/emerge markers rather than random points. Source: [Game Developer - Enter the Gungeon Q&A](https://www.gamedeveloper.com/design/q-a-the-guns-and-dungeons-of-i-enter-the-gungeon-i-)
- Biome/space principles should teach enemy behavior: Stray emerges into `LAMP_A`, Sentry holds the side-mouth, Racer/Bully pressure `LAMP_B`, preserving role clarity without new AI. Source: [Kotaku - Hades level design](https://kotaku.com/hades-level-design-is-less-random-than-it-seems-1845254545)
- Characters in top-down need readable direction and silhouettes; keeping rivals visible in pool centers protects the bite telegraph and dog body shape. Source: [Sandro Maglione - Top-down Pixel Art](https://www.sandromaglione.com/articles/pixel-art-top-down-game-sprite-design-and-animation)
- `MOTION_MODE_FLOATING` is appropriate for top-down `CharacterBody2D` because all collisions are treated as walls rather than floors/slopes. Source: [Godot CharacterBody2D docs](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html)
- Avoid rapid flicker or repeated high-contrast flashes in the light pass; sodium lamp flicker should be slow/subtle and not used as combat feedback. Source: [Game Accessibility Guidelines - Flicker](https://gameaccessibilityguidelines.com/avoid-flickering-images-and-repetitive-patterns/)

## Applied Principles

| Principle | Rationale | Trade-off | 30s playtest signal |
| --- | --- | --- | --- |
| Light spine before collision | The player should read two amber destinations before reading any wall graph. | Less geometry complexity in v3.0. | Player says "go to the next lamp" within 5s. |
| Dark spawn, lit fight | Rival silhouettes become readable only when they enter pools. | Less surprise than pure ambush. | Four rivals visibly step out of dark shoulders. |
| One side gully only | Keeps ref1/ref2 irregularity without rebuilding the v2 partition maze. | Fewer route choices. | Side mouth reads as a dark approach vector, not a room. |
| Props on pool edges | Chair/sacks teach verbs where the fight is legible. | Less decorative clutter in dark areas. | Player bites/kicks at least one prop during the first clear. |
| Camera-sized segment | 1920x1080 gives scroll discovery while keeping QA small. | Only two lamp spans. | Moving from chai spawn to `LAMP_B` scrolls the camera with no void. |
