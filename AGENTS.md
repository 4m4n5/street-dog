# Agent instructions — Street Dog

Instructions for **any** AI coding agent (Cursor, Codex, Claude Code, Claude Desktop, Windsurf, Cline, Kiro, etc.).

Human setup & workflow: [`README.md`](README.md)

## Project

- **2D game** — Godot 4.6, GDScript, GL Compatibility renderer
- **Physics:** built-in 2D (`CharacterBody2D`, `Area2D`, `RayCast2D`)
- **AI bridge:** Godot Catalyst MCP (`npx godot-catalyst`) + `addons/godot_catalyst`

**Do not use 3D nodes** (`CharacterBody3D`, `MeshInstance3D`, `Camera3D`, etc.) unless the human explicitly asks.

## Before making changes

1. Godot editor **open** on this project (2D viewport).
2. **Godot Catalyst** plugin enabled → panel **Connected** on port 6505.
3. **Codex:** `codex mcp list` must show `godot` enabled (see README → Codex setup).
4. Use MCP to inspect scenes/nodes/errors — **never invent node paths**.

## 2D node conventions

| Purpose | Node |
|---------|------|
| Player / NPC movement | `CharacterBody2D` + `CollisionShape2D` |
| Visuals | `Sprite2D` or `AnimatedSprite2D` |
| Camera | `Camera2D` (enable position smoothing as needed) |
| Triggers / pickups | `Area2D` |
| Ground / walls (tile-based) | `TileMapLayer` (Godot 4.x) |
| Parallax backgrounds | `Parallax2D` |
| UI | `CanvasLayer` → `Control` nodes |

**2D physics layers:** `world` (1), `player` (2), `enemies` (3), `interactables` (4).

## GDScript (Godot 4)

```gdscript
extends CharacterBody2D

@export var speed: float = 200.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()
```

No Godot 3 syntax: no `yield`, `setget`, or bare `export`.

## MCP — what to use

Prefer MCP tools over file guessing:

| Task | Approach |
|------|----------|
| Scene structure | MCP scene/node tools |
| Run + debug | MCP play/stop + read output/screenshots |
| Tilemaps | MCP tilemap tools |
| Sprites / collision | MCP 2D manipulation tools |
| Asset blockout | MCP CC0 search (Kenney packs) |
| Code quality | MCP LSP diagnostics |

`GODOT_TOOL_MODE=lite` if ~240 tools overwhelms the client.

## File layout

- `scenes/` — `.tscn` files
- `scripts/` — `.gd` files
- `assets/sprites/`, `assets/tilesets/`, `assets/audio/`

## Do / Don't

| Do | Don't |
|----|-------|
| Small, testable changes | One-shot entire game |
| `move_and_slide()` for kinematic 2D bodies | Mix 3D nodes into 2D scenes |
| Verify paths via MCP | Edit `.godot/` cache |
| Run → fix errors → re-run | Guess collision layer masks |

## Testing loop

1. Run (MCP or F5)
2. Read errors via MCP
3. Fix and re-run
4. Human playtests feel
