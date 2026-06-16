# Top-Down v1 Research Notes

Phase 0 research for the Street Dog top-down combat prototype.

## Cited Takeaways

- Hotline-style rooms need immediate purpose and flow: the Steam community level design guide warns against aimless point-and-click spaces and favors a preferred path with restrictions, alternate approaches, and playtesting from multiple routes. For Street Dog, the arena should read in under 2 seconds and still have more than one viable route. Source: [Steam - Essential Hotline Miami Level Design Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3305685660).
- Hotline level size should stay compact and saturated instead of filling the whole editor space. The same guide stresses smaller, denser layouts, varied room sizes, and enough cover to avoid an empty slab. Street Dog should use three compact pockets inside 1280x720, not a large open rectangle. Source: [Steam - Essential Hotline Miami Level Design Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=3305685660).
- Door-problem research frames the failure case as a player retreating to a threshold and turning the fight into a funnel. The fix is not just widening the door; the arena needs a more attractive position inside it. Street Dog's spawn needs a chai-stall foothold, then a commitment choke into the courtyard. Source: [Game Developer - The Door Problem of Combat Design](https://www.gamedeveloper.com/design/the-door-problem-of-combat-design).
- Footholds, hidden information, and AI territory should work together. The door-problem article specifically points to full-cover footholds, partitioned layers, and leashed enemies as ways to pull players into the arena without rewriting AI. Street Dog should hide the full main lane from spawn and keep each rival primarily in its own pocket. Source: [Game Developer - The Door Problem of Combat Design](https://www.gamedeveloper.com/design/the-door-problem-of-combat-design).
- Cover affects difficulty by controlling knowledge. Pete Ellis explains that low cover lets players track movement, while high cover blocks bodies and line of sight, forcing repositioning. Street Dog should treat sacks/chairs as low cover and chai/scooter/bench/interior walls as full movement blockers. Source: [Game Developer - How an Environment Layout Affects Difficulty](https://www.gamedeveloper.com/design/how-an-environment-layout-affects-difficulty).
- Open no-cover gaps create danger and movement pressure without changing enemy stats. The same environment-layout article describes no man's land and cover spacing as ways to encourage or suppress movement. Street Dog should leave 80-140px exposed gaps between cover islands so bites happen during committed movement. Source: [Game Developer - How an Environment Layout Affects Difficulty](https://www.gamedeveloper.com/design/how-an-environment-layout-affects-difficulty).
- Chokepoints are hand-authored flow-control tools, not accidental skinny hallways. World of Level Design notes that architecture, cover placement, and timing shape choke play, and that urban alleys/streets are natural choke contexts. Street Dog should use one 64px intentional choke plus a wider loop path, so the player can choose risk instead of being trapped in a corridor. Source: [World of Level Design - Choke Point Level Design](https://www.worldofleveldesign.com/categories/csgo-tutorials/csgo-principles-choke-point-level-design.php).
- Chokes work best when they support distance variety. World of Level Design emphasizes long/short, narrow/wide options and limiting routes to a manageable number. Street Dog should contrast the narrow entry choke with a wider courtyard and a bus-stop loop route. Source: [World of Level Design - Choke Point Level Design](https://www.worldofleveldesign.com/categories/csgo-tutorials/csgo-principles-choke-point-level-design.php).
- Enter the Gungeon makes the room matter through interactables: tables, barrels, chandeliers, coffins, and carts are readable environmental verbs. Street Dog should make Mumbai props bite-reactive, not decorative: chair kicks, sacks topple, boxes break, metal props clang or alert. Source: [Game Developer - Q&A: Enter the Gungeon](https://www.gamedeveloper.com/design/q-a-the-guns-and-dungeons-of-i-enter-the-gungeon-i-).
- Hades room kits separate gameplay readability from art polish. Ed Gorinstein's Hades Blocktober thread lists walls, half cover, traps, pillars, tables, urns, exits, spawn points, and biome-specific room principles; it also notes that greybox lighting should not obscure critical gameplay objects. Street Dog should build a clear kit first: wall, high cover, low cover, destructible, kickable, alerting metal. Source: [Ed Gorinstein Hades level design thread](https://threadreaderapp.com/thread/1311777010239193088.html).
- Hades uses chamber size and shape to pace difficulty: smaller rooms appear earlier and larger rooms later, while traps remain supplementary rather than the whole encounter. Street Dog's single-screen version should make the entry alcove forgiving, the courtyard broader, and the bus-stop pocket a late pressure pocket. Source: [Ed Gorinstein Hades level design thread](https://threadreaderapp.com/thread/1311777010239193088.html).
- Top-down sprites must show the character from above, not as a platformer side profile. Sandro Maglione notes that top-down sprites expose more of the top of the head and use lighting/shading and smaller facial features to communicate the camera angle. Street Dog dogs should have symmetric ears, forward eyes, shoulders, paws, and tail around a rotating +X silhouette. Source: [Sandro Maglione - Top-down game pixel art](https://www.sandromaglione.com/articles/pixel-art-top-down-game-sprite-design-and-animation).
- Unit readability beats detail. VSQUAD's 2D unit design guide uses a 0.5-second readability test and emphasizes silhouette, color, and simplified details for top-down/mobile-scale units. Street Dog should separate player/rivals by silhouette scale and palette, with the bully slightly broader/darker. Source: [VSQUAD - 2D unit art for games](https://vsquad.art/blog/2d-unit-art-for-games-styles-and-production-process).
- Chawl identity is spatial, not just texture. Architizer describes Mumbai chawls as dense, corridor-and-courtyard housing tied to social life and redevelopment pressure. Street Dog should show a chawl wall with lit windows, dripping plaster, wires, and a cramped communal lane rather than a generic concrete box. Source: [Architizer - Mumbai's Chawls](https://architizer.com/blog/inspiration/stories/mumbais-chawls-indias-housing-could-soon-disappear/).
- Chawl layouts commonly include long passages, central stairs, and small courtyards, while ground-floor shops/businesses can be part of the building. That supports a top boundary chawl wall, a courtyard pocket, and a bottom shop lip with chai/vendor clutter. Source: [Wikipedia - Chawl](https://en.wikipedia.org/wiki/Chawl).

## Feel + Layout Targets For This Game

- The full arena should be readable in under 2 seconds: three pockets, one main lane, one choke, one loop option.
- Use internal partitions instead of a flat rectangle: wall islands must create hidden information and footholds without breaking the single-screen 1280x720 frame.
- Player spawn starts in a protected chai-stall entry alcove; the player can see part of the lane but not both rivals.
- Main choke width target: 64px, with no passage narrower than 56px and main route lanes mostly 72-96px.
- Use two route personalities: a narrow deliberate entry choke into the courtyard and a wider partial loop toward the bus-stop alcove.
- High cover blocks movement and sight: chai counter, scooter, BEST bench, partition walls.
- Low cover shapes movement but remains visually trackable: plastic chair, gunny sacks, scattered sack debris, cardboard boxes.
- Cover islands should sit 80-140px apart to create exposed dog-length commitments, not continuous safety.
- Rivals should stay pocketed: grunt in courtyard, bully in bus-stop alcove, with careless looping creating a pinch.
- Dogs must read as bird's-eye silhouettes at 0.5 seconds: symmetric ears/paws, forward eyes, body shoulders, short tail, no permanent side-facing snout.
- Mumbai night identity should come from sodium amber pools, wet paver sheen, chawl windows, chai stall, BEST stripe, tangled wire hints, puddles, sacks, scooter, and vendor cardboard.

## Palette Targets

- Asphalt / gully edge: `Color("#090B0D")` to `Color("#13181C")`
- Wet paver footpath: `Color("#272622")` to `Color("#2E2C28")`
- Monsoon sheen: `Color(0.95, 0.68, 0.34, 0.10)` to `Color(1.0, 0.78, 0.42, 0.16)`
- Sodium pools: `Color(0.949, 0.557, 0.259, 0.06)` from `#F28E42` at 5-8% alpha
- Chawl plaster: `Color("#1E1F1D")`
- Lit chawl windows: `Color(0.902, 0.600, 0.282, 0.65)` from `#E69948` at 65% alpha
- Chai stall: `Color("#2E1A0B")`
- Chai stall amber lip: `Color("#F29E47")`
- Puddle: `Color(0.090, 0.165, 0.220, 0.62)` from `#172A38` at 62% alpha
- BEST stripe: `Color("#0E352E")` with amber trim `Color("#F29E47")`
- Player dog: body `Color("#73522E")`, head `Color("#80603A")`
- Rival grunt: `Color("#2E2F2D")`
- Rival bully: darker grey `Color("#222423")` with 10% larger shoulders
- Rival bite telegraph wedge: `Color("#FFC833")`
