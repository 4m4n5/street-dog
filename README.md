# Street Dog

A **2D** Godot **4.6** game — side-view / top-down street adventure (TBD).

AI-assisted development via [Godot Catalyst](https://portal.fireal.dev/godot-catalyst/) (MCP). Works with any MCP-compatible agent: Cursor, Codex, Claude Code, Claude Desktop, Windsurf, Cline, Kiro, etc.

## Stack

| Layer | Choice |
|-------|--------|
| Engine | Godot 4.6, **2D** (`CharacterBody2D`, `Sprite2D`, `TileMapLayer`, `Camera2D`) |
| Renderer | GL Compatibility (broad GPU support) |
| Physics | Built-in **2D** physics (gravity `980`) |
| Viewport | 1280×720, canvas stretch |
| Texture filter | Nearest (pixel-crisp; switch to linear in Project Settings for HD art) |
| Language | GDScript |
| AI bridge | Godot Catalyst MCP + `addons/godot_catalyst` plugin |

## Requirements

| Tool | Version |
|------|---------|
| [Godot](https://godotengine.org/download) | 4.6+ |
| [Node.js](https://nodejs.org/) | 18+ |
| [Godot Catalyst](https://portal.fireal.dev/godot-catalyst/) | CLI + license (7-day trial) |

## Quick start

```bash
git clone git@github.com:4m4n5/street-dog.git
cd street-dog

npm install -g godot-catalyst
godot-catalyst --activate <license-key>   # skip during trial

godot-catalyst --install-addon .          # refresh addon if CLI is newer

# Open in Godot → Project → Plugins → enable "Godot Catalyst"
godot project.godot
```

---

## Tools you have

### Godot editor (your hands)

| Control | Action |
|---------|--------|
| **F5** | Run project |
| **F6** | Run current scene |
| **F7** | Pause |
| **F8** | Stop |
| **Ctrl+S** / **Cmd+S** | Save scene |
| **W** / move gizmo | Move node (2D viewport) |
| **2D / 3D** tab (top) | Stay in **2D** — this project is 2D-only |
| **TileMap** editor | Paint ground, walls, props |
| **Animation** panel | Sprite frames, tweens |
| **Inspector** | Node properties, collision layers, export vars |
| **FileSystem** | Import sprites, audio (`assets/`) |

**Physics layers** (Project → Layer Names → 2D Physics):

| Layer | Name |
|-------|------|
| 1 | `world` |
| 2 | `player` |
| 3 | `enemies` |
| 4 | `interactables` |

### Godot Catalyst MCP (AI agent hands)

Godot listens on WebSocket **port 6505**. Your agent runs `npx godot-catalyst`, which connects and exposes **240+ tools**.

**2D-relevant MCP categories:**

| Category | What agents can do |
|----------|-------------------|
| **Scenes & nodes** | Create/open/save scenes; add `CharacterBody2D`, `Sprite2D`, `Camera2D`, `Area2D`, etc. |
| **2D manipulation** | Sprites, collision shapes, tilemaps, parallax, 2D camera |
| **Scripts** | Create/edit/attach GDScript; run snippets |
| **Animation** | `AnimatedSprite2D`, AnimationPlayer tracks |
| **TileMaps** | Paint cells, fill regions, layers |
| **Physics (2D)** | `CollisionShape2D`, layers/masks, raycasts |
| **Input** | Map actions; simulate keys during play |
| **Build** | Play/stop project; capture viewport screenshots |
| **Editor** | Undo/redo, selection, project settings |
| **LSP** | Diagnostics, completion, go-to-definition |
| **Debug** | Breakpoints, stack, variables (DAP on port 6006) |
| **CC0 assets** | Search Kenney, Poly Haven, AmbientCG — ideal for 2D sprite/tile packs |
| **Visual testing** | Screenshots, frame capture for AI verify loops |

Set `GODOT_TOOL_MODE=lite` (~80 tools) if your client struggles with the full list.

### Code editor (optional)

[godot-tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) in VS Code / Cursor — GDScript LSP on port **6005**. See [`.vscode/`](.vscode/).

---

## AI agent setup (MCP)

**Before each session:** open Godot with Catalyst enabled. The bottom panel shows **Connected** once your agent's MCP server is running.

Copy [`mcp.example.json`](mcp.example.json) and set absolute paths:

```json
{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["-y", "godot-catalyst"],
      "env": {
        "GODOT_PROJECT_PATH": "/absolute/path/to/street-dog",
        "GODOT_PATH": "/path/to/Godot.app/Contents/MacOS/Godot"
      }
    }
  }
}
```

| Client | Config |
|--------|--------|
| **Cursor** | `.cursor/mcp.json` (workspace) or project settings |
| **Codex** | **Global required** — see [Codex setup](#codex-setup) below |
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Claude Code | `claude mcp add godot -- "$(pwd)/scripts/mcp/godot-catalyst.sh"` |
| Windsurf / Cline / Kiro | Same JSON shape as `mcp.example.json` |

Or use the repo launcher (sets `GODOT_PROJECT_PATH` automatically):

```bash
./scripts/mcp/godot-catalyst.sh
```

### Codex setup

Codex reads **`~/.codex/config.toml`** globally. **Do not** put `[mcp_servers]` in this repo's `.codex/config.toml` with a relative command — it overrides the global config and breaks the VS Code extension (Codex spawns MCP from a different cwd).

**One-time per machine** (from repo root, Godot open):

```bash
codex mcp remove godot 2>/dev/null
codex mcp add godot \
  --env GODOT_PATH=/Applications/Godot.app/Contents/MacOS/Godot \
  -- "$(pwd)/scripts/mcp/godot-catalyst.sh"

# Verify the command is an ABSOLUTE path (not scripts/mcp/...)
codex mcp get godot
```

Trust entry in `~/.codex/config.toml`:

```toml
[projects."/absolute/path/to/street-dog"]
trust_level = "trusted"

[mcp_servers.godot]
enabled = true
command = "/absolute/path/to/street-dog/scripts/mcp/godot-catalyst.sh"
startup_timeout_sec = 60

[mcp_servers.godot.env]
GODOT_PATH = "/Applications/Godot.app/Contents/MacOS/Godot"
```

**After changes:** fully **quit and reopen** VS Code/Cursor (reload window is often not enough). Start a **new** Codex thread. Tools appear as `mcp__godot__*`.

In a Codex session, run `/mcp` to confirm `godot` is connected with tools listed.

**Troubleshooting**

| Symptom | Fix |
|---------|-----|
| `codex mcp get godot` shows relative `scripts/mcp/...` | Remove `[mcp_servers]` from repo `.codex/config.toml`; re-run `codex mcp add` |
| `codex doctor` shows MCP servers `0` | Re-run `codex mcp add` above |
| Godot Connected but Codex has no tools | Quit VS Code completely; new Codex thread |
| MCP starts but 0 tools | Godot editor must be open; plugin enabled on :6505 |

### Recommended Godot editor settings

**Editor → Editor Settings** (Advanced on):

- **Text Editor → Auto Reload Scripts on External Change** — on
- **Network → Language Server** — on (port `6005`)
- **Network → Debug Adapter** — on (port `6006`)
- **Text Editor → External** — optional (`cursor`, `code`, `zed`, …)

---

## Typical development workflow

```
┌─────────────┐     describe task      ┌──────────────┐
│   You       │ ─────────────────────► │  AI agent    │
│  (design,   │                        │  (Cursor,    │
│  playtest)  │ ◄───────────────────── │   Claude,    │
└──────┬──────┘     screenshots,      │   Kiro, …)   │
       │             errors, diffs      └──────┬───────┘
       │ F5 feel pass                          │ MCP
       ▼                                       ▼
┌─────────────────────────────────────────────────────┐
│  Godot 4.6 — 2D viewport, scenes, TileMaps, F5 play │
│  Godot Catalyst plugin (:6505)                      │
└─────────────────────────────────────────────────────┘
```

### Session loop

1. **Open Godot** — project loaded, Catalyst plugin on, panel listening on `:6505`.
2. **Start agent** — MCP `godot` server configured and connected (panel: **Connected**).
3. **Prompt** — small, testable tasks (*"Add a `CharacterBody2D` player with WASD and a `Camera2D`"*).
4. **Agent acts** — MCP creates nodes, writes scripts, runs game, reads errors, screenshots.
5. **You playtest** — **F5**, judge movement, readability, fun.
6. **Iterate** — tweak in prompts, Inspector, or script edits; repeat.

### Division of labor

| You | AI agent |
|-----|----------|
| Game feel, pacing, art direction | Scaffold scenes, wire collisions, write controllers |
| F5 playtesting | Error-fix loops, boilerplate, refactors |
| Final art/audio choices | CC0 asset search, import wiring, TileMap layout drafts |
| Scope and design calls | Input maps, signal hooks, UI structure |

### 2D asset workflow

| Source | Use for |
|--------|---------|
| **Kenney** (via MCP CC0 search) | Tilesets, simple props, UI — great for blockout |
| **itch.io** / **OpenGameArt** | Character sprites, street backgrounds |
| **Aseprite** / **Pixelorama** | Custom dog sprites, export PNG sprite sheets |
| **Audacity** / **Freesound** | SFX (check license) |

Drop files in `assets/sprites/`, `assets/tilesets/`, `assets/audio/`. Godot imports on focus.

**Prompt example:** *"Import `assets/sprites/dog_sheet.png` as a sprite sheet and set up `AnimatedSprite2D` with idle/walk animations."*

### Testing loop (agent or human)

1. Run project (MCP play or **F5**)
2. Read Output / Debugger (MCP or Godot panel)
3. Fix scripts or scene issues
4. Re-run until clean
5. Human pass on **feel** — speed, jump arc, camera follow, readability

---

## Project layout

```
├── project.godot
├── addons/godot_catalyst/   # MIT plugin
├── scenes/                  # .tscn — levels, player, UI
├── scripts/                 # GDScript
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   └── audio/
├── AGENTS.md                # rules for AI agents
└── mcp.example.json
```

## Agent conventions

Read [`AGENTS.md`](AGENTS.md) — Godot 4 GDScript rules, 2D node preferences, MCP usage.

## License

Game code: TBD. Catalyst **editor plugin** is MIT. Catalyst **MCP CLI** is proprietary — [purchase](https://portal.fireal.dev/godot-catalyst/) after trial.
