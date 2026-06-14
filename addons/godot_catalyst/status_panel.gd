@tool
extends MarginContainer

const MAX_LOG_ENTRIES := 5
const MCP_CONFIG_SNIPPET := """{
  "mcpServers": {
    "godot": {
      "command": "npx",
      "args": ["godot-catalyst"],
      "env": {
        "GODOT_PROJECT_PATH": "/path/to/your/godot/project"
      }
    }
  }
}"""
const DOCS_URL := "https://portal.fireal.dev/godot-catalyst/"

var _status_label: Label
var _version_label: Label
var _port_label: Label
var _actions_label: Label
var _calls_label: Label
var _uptime_label: Label
var _copy_config_button: Button
var _docs_button: Button
var _log_list: VBoxContainer

var _connected: bool = false
var _connect_time_unix: float = 0.0
var _call_count: int = 0
var _recent_calls: Array = []  # Array of { method: String, time_unix: float }
var _uptime_timer: Timer

# Cached info set before _ready, applied once labels exist.
var _pending_port: int = -1
var _pending_version: String = ""
var _pending_action_count: int = -1


func _ready() -> void:
	_status_label = $VBox/HeaderRow/StatusLabel
	_version_label = $VBox/HeaderRow/VersionLabel
	_port_label = $VBox/HeaderRow/PortLabel
	_actions_label = $VBox/HeaderRow/ActionsLabel
	_calls_label = $VBox/HeaderRow/CallsLabel
	_uptime_label = $VBox/HeaderRow/UptimeLabel
	_copy_config_button = $VBox/HeaderRow/CopyConfigButton
	_docs_button = $VBox/HeaderRow/DocsButton
	_log_list = $VBox/LogScroll/LogList

	_copy_config_button.pressed.connect(_on_copy_config_pressed)
	_docs_button.pressed.connect(_on_docs_pressed)

	_uptime_timer = Timer.new()
	_uptime_timer.wait_time = 1.0
	_uptime_timer.autostart = false
	_uptime_timer.timeout.connect(_refresh_uptime)
	add_child(_uptime_timer)

	_apply_disconnected_style()

	# Apply any info set before _ready fired
	if _pending_port >= 0:
		_port_label.text = "Port %d" % _pending_port
	if not _pending_version.is_empty():
		_version_label.text = "v%s" % _pending_version
	if _pending_action_count >= 0:
		_actions_label.text = "%d actions" % _pending_action_count


func set_info(port: int, plugin_version: String, action_count: int) -> void:
	_pending_port = port
	_pending_version = plugin_version
	_pending_action_count = action_count
	if _port_label:
		_port_label.text = "Port %d" % port
	if _version_label:
		_version_label.text = "v%s" % plugin_version
	if _actions_label:
		_actions_label.text = "%d actions" % action_count


func set_connected(connected: bool) -> void:
	_connected = connected
	if connected:
		_connect_time_unix = Time.get_unix_time_from_system()
		_apply_connected_style()
		if _uptime_timer:
			_uptime_timer.start()
		_refresh_uptime()
	else:
		_apply_disconnected_style()
		if _uptime_timer:
			_uptime_timer.stop()
		if _uptime_label:
			_uptime_label.text = "—"


func log_call(method: String) -> void:
	_call_count += 1
	if _calls_label:
		_calls_label.text = "%d calls" % _call_count

	_recent_calls.push_front({
		"method": method,
		"time_unix": Time.get_unix_time_from_system(),
	})
	if _recent_calls.size() > MAX_LOG_ENTRIES:
		_recent_calls.resize(MAX_LOG_ENTRIES)
	_rebuild_log()


func _apply_connected_style() -> void:
	if _status_label:
		_status_label.text = "● Connected"
		_status_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))


func _apply_disconnected_style() -> void:
	if _status_label:
		_status_label.text = "● Disconnected"
		_status_label.add_theme_color_override("font_color", Color(0.85, 0.35, 0.3))


func _refresh_uptime() -> void:
	if not _uptime_label or not _connected:
		return
	var elapsed := int(Time.get_unix_time_from_system() - _connect_time_unix)
	_uptime_label.text = _format_duration(elapsed)


func _format_duration(total_seconds: int) -> String:
	if total_seconds < 60:
		return "%ds" % total_seconds
	if total_seconds < 3600:
		return "%dm %ds" % [total_seconds / 60, total_seconds % 60]
	return "%dh %dm" % [total_seconds / 3600, (total_seconds % 3600) / 60]


func _rebuild_log() -> void:
	if not _log_list:
		return

	for child in _log_list.get_children():
		child.queue_free()

	if _recent_calls.is_empty():
		var hint := Label.new()
		hint.text = "Waiting for tool calls…"
		hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_log_list.add_child(hint)
		return

	var now := Time.get_unix_time_from_system()
	for entry in _recent_calls:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var time_label := Label.new()
		time_label.custom_minimum_size = Vector2(56, 0)
		time_label.text = _relative_time(now - entry["time_unix"])
		time_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		row.add_child(time_label)

		var method_label := Label.new()
		method_label.text = entry["method"]
		row.add_child(method_label)

		_log_list.add_child(row)


func _relative_time(seconds_ago: float) -> String:
	var s := int(seconds_ago)
	if s < 1:
		return "just now"
	if s < 60:
		return "%ds ago" % s
	if s < 3600:
		return "%dm ago" % (s / 60)
	return "%dh ago" % (s / 3600)


func _on_copy_config_pressed() -> void:
	DisplayServer.clipboard_set(MCP_CONFIG_SNIPPET)
	var original_text := _copy_config_button.text
	_copy_config_button.text = "Copied ✓"
	_copy_config_button.disabled = true
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(_copy_config_button):
		_copy_config_button.text = original_text
		_copy_config_button.disabled = false


func _on_docs_pressed() -> void:
	OS.shell_open(DOCS_URL)
