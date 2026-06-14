@tool
extends EditorPlugin

const AUTOLOAD_NAME := "CatalystGameAgent"
const AUTOLOAD_PATH := "res://addons/godot_catalyst/runtime/catalyst_game_agent.gd"
const DebuggerPluginScript := preload("res://addons/godot_catalyst/catalyst_debugger_plugin.gd")

var _mcp_server: Node
var _tool_executor: Node
var _status_panel: Control
var debugger_plugin  # CatalystDebuggerPlugin — untyped to avoid class_name resolution ordering issues on plugin reload


func _enter_tree() -> void:
	# Create the MCP WebSocket server
	_mcp_server = preload("res://addons/godot_catalyst/mcp_server.gd").new()
	_mcp_server.name = "MCPServer"
	add_child(_mcp_server)

	# Create the tool executor (dispatches JSON-RPC to handlers)
	_tool_executor = preload("res://addons/godot_catalyst/tool_executor.gd").new()
	_tool_executor.name = "ToolExecutor"
	add_child(_tool_executor)
	_tool_executor.setup(self)

	# Create the status panel
	_status_panel = preload("res://addons/godot_catalyst/status_panel.tscn").instantiate()
	add_control_to_bottom_panel(_status_panel, "Godot Catalyst")

	# Debugger bridge: editor ↔ running game
	debugger_plugin = DebuggerPluginScript.new()
	add_debugger_plugin(debugger_plugin)

	# Register the game-side autoload so the running game can respond to
	# debugger messages. Idempotent — skip if user already has it.
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)

	# Wire up: server routes requests to executor
	_mcp_server.request_received.connect(_on_request_received)
	_mcp_server.client_connected.connect(_on_client_connected)
	_mcp_server.client_disconnected.connect(_on_client_disconnected)

	# Start listening
	var port := int(ProjectSettings.get_setting("godot_catalyst/port", 6505))
	_mcp_server.start_server(port)
	print("[Godot Catalyst] Plugin loaded, WebSocket server listening on port %d" % port)

	# Populate static panel info once handlers are registered
	if _status_panel and _status_panel.has_method("set_info"):
		var plugin_version: String = _read_plugin_version()
		var action_count: int = _tool_executor.get_action_count() if _tool_executor.has_method("get_action_count") else 0
		_status_panel.set_info(port, plugin_version, action_count)


func _exit_tree() -> void:
	if debugger_plugin:
		remove_debugger_plugin(debugger_plugin)
		debugger_plugin = null

	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)

	if _mcp_server:
		_mcp_server.stop_server()
		remove_child(_mcp_server)
		_mcp_server.queue_free()

	if _tool_executor:
		remove_child(_tool_executor)
		_tool_executor.queue_free()

	if _status_panel:
		remove_control_from_bottom_panel(_status_panel)
		_status_panel.queue_free()

	print("[Godot Catalyst] Plugin unloaded")


func _on_request_received(peer_id: int, id: String, method: String, params: Dictionary) -> void:
	# Handle ping directly (don't count in the visible call log)
	if method == "ping":
		_mcp_server.send_response(peer_id, id, {"pong": true, "timestamp": Time.get_unix_time_from_system()})
		return

	if _status_panel and _status_panel.has_method("log_call"):
		_status_panel.log_call(method)

	# Dispatch to tool executor. Handlers may be coroutines (await); tool_executor.execute
	# is itself awaitable so we always await here.
	var result: Variant = await _tool_executor.execute(method, params)
	if not result is Dictionary:
		result = {"success": true, "result": result}
	var dict_result: Dictionary = result
	if dict_result.has("error"):
		_mcp_server.send_error(peer_id, id, dict_result["error"]["code"], dict_result["error"]["message"], dict_result["error"].get("data"))
	else:
		_mcp_server.send_response(peer_id, id, dict_result)


func _on_client_connected(peer_id: int) -> void:
	print("[Godot Catalyst] Client connected: %d" % peer_id)
	if _status_panel and _status_panel.has_method("set_connected"):
		_status_panel.set_connected(true)


func _on_client_disconnected(peer_id: int) -> void:
	print("[Godot Catalyst] Client disconnected: %d" % peer_id)
	if _status_panel and _status_panel.has_method("set_connected"):
		_status_panel.set_connected(false)


func _read_plugin_version() -> String:
	var cfg := ConfigFile.new()
	var err := cfg.load("res://addons/godot_catalyst/plugin.cfg")
	if err != OK:
		return "?"
	return str(cfg.get_value("plugin", "version", "?"))
