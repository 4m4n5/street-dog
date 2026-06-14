# Street Dog

Godot **4.6** game — 3D, Jolt Physics, Forward+ renderer.

AI-assisted development via [Godot Catalyst](https://portal.fireal.dev/godot-catalyst/) (MCP). Works with any MCP-compatible agent: Cursor, Codex, Claude Code, Claude Desktop, Windsurf, Cline, Kiro, etc.

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

# MCP CLI (each contributor needs their own license)
npm install -g godot-catalyst
godot-catalyst --activate <license-key>   # skip during trial

# Refresh addon if CLI is newer than the committed plugin
godot-catalyst --install-addon .

# Open in Godot → Project → Plugins → enable "Godot Catalyst"
godot project.godot   # or open project.godot from the editor UI
```

## AI agent setup (MCP)

Godot runs a **WebSocket server** (port `6505`). Your agent runs the **MCP client** (`godot-catalyst`), which connects to it.

**Before each session:** open the project in Godot with the Catalyst plugin enabled. The bottom-panel status shows **Connected** once your agent's MCP server is running.

### MCP server config

Copy [`mcp.example.json`](mcp.example.json) and set `GODOT_PROJECT_PATH` to this repo's absolute path.

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

| Client | Config location |
|--------|-----------------|
| Cursor | `.cursor/mcp.json` in repo or user settings |
| Claude Desktop | `~/Library/Application Support/Claude/claude_desktop_config.json` |
| Claude Code | `claude mcp add godot -e GODOT_PROJECT_PATH=... -- npx -y godot-catalyst` |
| Windsurf / Cline | Client-specific MCP settings (same JSON shape) |
| Codex | `codex mcp add godot -e GODOT_PROJECT_PATH=... -- npx -y godot-catalyst` |

Optional env vars: `GODOT_TOOL_MODE` (`full` \| `lite` \| `minimal`), `MESHY_API_KEY`, `TRIPO_API_KEY`.

### Recommended Godot editor settings

**Editor → Editor Settings** (enable Advanced):

- **Text Editor → Auto Reload Scripts on External Change** — on
- **Network → Language Server** — on (port `6005`)
- **Network → Debug Adapter** — on (port `6006`)

Optional: point **Text Editor → External** at your editor (`cursor`, `code`, `zed`, etc.).

### Optional: VS Code / Cursor extension

Install [godot-tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) for GDScript LSP in the editor. See [`.vscode/`](.vscode/).

## Project layout

```
├── project.godot
├── addons/godot_catalyst/   # MIT plugin (upgrade via godot-catalyst --install-addon)
├── scenes/                  # .tscn scenes (created during development)
├── scripts/                 # GDScript
├── assets/                  # models, textures, audio
├── AGENTS.md                # instructions for AI coding agents
└── mcp.example.json         # MCP config template
```

## Development workflow

1. Open Godot (plugin on, port 6505 listening).
2. Start your AI agent with the `godot` MCP server configured.
3. Describe tasks in natural language — agents can create scenes, write GDScript, run the game, read errors, take screenshots.
4. Playtest with **F5**; iterate on feel manually or via prompts.

Read [`AGENTS.md`](AGENTS.md) for conventions agents should follow.

## License

Game code: TBD. Godot Catalyst **editor plugin** (`addons/godot_catalyst/`) is [MIT](https://github.com/shameindemgg/godot-catalyst). Catalyst **MCP CLI** is proprietary — [purchase](https://portal.fireal.dev/godot-catalyst/) required after trial.
