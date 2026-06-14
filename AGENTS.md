# Agent instructions — Street Dog

Instructions for **any** AI coding agent (Cursor, Codex, Claude Code, Claude Desktop, Windsurf, Cline, Kiro, etc.) working on this repo.

Human setup: [`README.md`](README.md)

## Project

- **Engine:** Godot 4.6, GDScript, Jolt Physics (3D), Forward+
- **AI bridge:** Godot Catalyst MCP (`npx godot-catalyst`) + `addons/godot_catalyst` plugin

## Before making changes

1. Godot editor must be **open** on this project.
2. **Godot Catalyst** plugin enabled (**Project → Plugins**).
3. MCP client connected (Godot Catalyst panel shows **Connected** on port 6505).
4. Use MCP tools to inspect scenes/nodes/errors — **do not invent node paths**.

## What agents should do

| Do | Don't |
|----|-------|
| Use MCP to read scene tree, run game, capture errors/screenshots | Guess `res://` paths or node names |
| Write Godot **4.x** GDScript (`@export`, `await`, signals) | Use Godot 3 syntax (`yield`, `setget`, bare `export`) |
| Make small, testable changes per task | Try to one-shot an entire game |
| Run play → read errors → fix → re-run | Edit `.godot/` cache (gitignored) |

## GDScript (Godot 4)

```gdscript
# Good
@export var speed: float = 5.0
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _physics_process(delta: float) -> void:
    await get_tree().process_frame
```

## MCP capabilities (Godot Catalyst)

Scenes, nodes, scripts, resources, 2D/3D objects, animation, audio, physics, navigation, play/stop, input simulation, screenshots, LSP diagnostics, DAP debugging, CC0 asset search (Kenney, Poly Haven, AmbientCG).

Set `GODOT_TOOL_MODE=lite` if the client struggles with ~240 tools.

## Conventions

- Scenes in `scenes/`, scripts in `scripts/`, assets in `assets/`
- Typed GDScript where it helps readability
- Prefer `CharacterBody3D` for player movement (Jolt is configured)
- Commit scenes, scripts, and assets — never `.godot/`

## Testing loop

1. Run project (MCP or F5 in editor)
2. Read console / debugger output via MCP
3. Fix scripts or scene issues
4. Re-run until clean
5. Human playtests for game feel
