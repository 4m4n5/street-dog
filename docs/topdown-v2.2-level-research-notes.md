# Topdown v2.2 Level Research Notes — Gully Street Network

Date: 2026-06-16
Task: Replace "one room + partitions" with authentic Mumbai night **gully** topology.

Extends: `topdown-v1-research-notes.md`, `topdown-v2.1-level-enemy-research-notes.md`

---

## Cited Research Bullets

### Urban street grammar (GTA 1/2 / classic top-down city)

- **GTA2 map editor (DMA Design):** Cities are built from **block types** — road, pavement, field, building air — not one hollow rectangle. WikiGTA explicitly warns: *"Try not to make very large buildings. Large buildings can make a map very boring and force players to make long detours. **Smaller buildings with alleys between them make a map more interesting.**"* Street Dog should treat chawl shop fronts and housing blocks as **footprints** that carve walkable gullies, not interior partition walls inside a single arena slab.
  URL: https://en.wikigta.org/wiki/Creating_buildings_(GTA2)

- **GTA2 roads:** Junctions are authored as **connected path graphs** (green arrows on road blocks); pavements sit beside drivable lanes so players can bypass congestion. For a dog-scale 1280×720 screen, translate this to: **one readable wet lane + one pavement strip + building shoulders** — three parallel bands, not a symmetric box with arbitrary dividers.
  URL: https://en.wikigta.org/wiki/Creating_roads_(GTA2)

- **GTA3 district analysis (top-down road hierarchy):** Cities read when **main roads split districts into chunks**, then **secondary roads**, then **alleys** — each tier shorter and narrower. Street Dog's single screen should show at least **two tiers** (main gully + side by-lane) with a visible **T or Y fork**, not equal-width rooms separated by full-height interior walls.
  URL: https://iuliu-cosmin-oniscu.medium.com/open-world-analysis-gta-3-5c04c957a3eb

### Mumbai spatial hierarchy (authentic gully, not generic arena)

- **Chawl neighbourhood hierarchy (Disegno / academic):** Real Mumbai housing orders space as **wadi** (courtyard) → **narrow lanes between chawls** (shops, mills) → **nukkad** (lane junction, chai corner) → **chowk** (square meeting arterial traffic). A top-down night gully should name and place these **outdoor** nodes — not simulate them as walled rooms inside one playpen.
  URL: https://disegnojournal.com/newsfeed/the-making-and-raising-of-mumbai-housing

- **IJARSET chawl study:** **Gully/by-lane** joins chawls and carries essential services (laundry, mills, shops). **Nukkad** is the less obvious junction where smaller gullies meet — typically chai, newspaper, seating under a tree. **Chowk** is the crossroads where gullies meet arterials — highest activity. Street Dog spawn → first commit should feel like leaving a **nukkad** into a **gully**, not opening a door into a courtyard room.
  URL: https://www.ijraset.com/best-journal/mumbai-chawls-resettlement-vs-chawl-culture-and-possible-solutions

- **Sangam Gully (urbz):** Gullies are **activity corridors** shaped by daily life — workshops, ground-floor shops, wires, organic structure — not planner-drawn rectangles. Density comes from **building mass along edges**, with the playable path in the **negative space** between facades.
  URL: https://urbz.net/articles/multifunctional-buildings-sangam-gully

- **Architizer chawls:** Ground-floor storefronts on narrow lanes set mixed-use street life; external corridors and balconies read as **facade depth** on the top-down edge, not interior partitions.
  URL: https://architizer.com/blog/inspiration/stories/mumbais-chawls-indias-housing-could-soon-disappear/

### Anti-pattern: partitioned single room

- **Michael Barclay arena guidelines:** Combat spaces need **multiple exits** and routes that feel **non-linear**; splitting one corridor in two helps, but **interiors with only two entries still feel like rooms**. Prefer **exterior** circulation with 3+ way forks where possible.
  URL: https://mikebarclay.co.uk/my-level-design-guidelines/

- **Game Developer — Making Better Hallways:** Long interior corridors are a necessary evil; the fix is **remove geometry to open vistas** or add storytelling — i.e. make the path **feel outdoor and connected**, not a hallway between artificial doors. Street Dog's monsoon gully should read as **open-air** with building shoulders, not a slab with `SpawnPartition` walls.
  URL: https://www.gamedeveloper.com/design/making-better-hallways

- **Door problem (retained):** Foothold cover still required — but foothold is a **chai nukkad alcove** on the street edge, not a room behind a partition wall.
  URL: https://www.gamedeveloper.com/design/the-door-problem-of-combat-design

### Top-down layout craft (retained from v2.1)

- Chokes at **lane mouths** (56–72px) vs wider **by-lanes** (88–110px). WoLD choke principles apply to **street width**, not interior doorways.
  URL: https://www.worldofleveldesign.com/categories/csgo-tutorials/csgo-principles-choke-point-level-design.php

- Cover islands 80–140px apart on **open lane** segments; Gungeon props remain verbs.
  URL: https://www.gamedeveloper.com/design/q-a-the-guns-and-dungeons-of-i-enter-the-gungeon-i-

- Macro → meso → micro (DOU): Block **building footprints** first, then **lane graph**, then props/wires/puddles.
  URL: https://gamedev.dou.ua/blogs/level-design-basics-part-2/

---

## Layout Targets for v2.2

| Metric | Target |
|--------|--------|
| Readability | In <3s after first corner, player can name **main gully** vs **side by-lane** |
| Topology | **Outdoor lane network** — ≥1 T/Y fork, ≥1 by-lane, ≥1 chowk/nukkad node |
| Anti-pattern | No single 1280×720 rectangle with ≥3 full-height interior partition walls |
| Building mass | ≥60% of perimeter + internal **facade** edges are building shoulders, not `Partition` nodes |
| Mumbai nodes | Nukkad spawn (chai), gully fork, wadi/chowk pocket, BEST chowk, laundry on facade |
| Hidden spawn | Zero rival silhouettes from nukkad; first sighting Stray after lane commit |
| Combat scope | Preserve v2.1 archetypes, bite FSM, room clear — **layout may be rebuilt from scratch** |
