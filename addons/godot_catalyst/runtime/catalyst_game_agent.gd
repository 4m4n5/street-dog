extends Node
## Autoloaded in the running game by the Godot Catalyst editor plugin.
## Registers an EngineDebugger message capture so the editor can request
## runtime operations (screenshots, eval, input simulation, node inspection)
## over Godot's debug channel.
##
## Wire format: every request's data array starts with an int req_id. The
## response message uses the same req_id so the editor can correlate.

const PREFIX := "catalyst"


func _ready() -> void:
	if not EngineDebugger.is_active():
		return
	EngineDebugger.register_message_capture(PREFIX, _on_message)


func _exit_tree() -> void:
	if EngineDebugger.is_active() and EngineDebugger.has_capture(PREFIX):
		EngineDebugger.unregister_message_capture(PREFIX)


func _on_message(message: String, data: Array) -> bool:
	match message:
		"screenshot":
			_handle_screenshot(data)
			return true
		"ping":
			_reply(data, "pong", [Time.get_unix_time_from_system()])
			return true
		"eval":
			_handle_eval(data)
			return true
		"get_tree":
			_handle_get_tree(data)
			return true
		"inspect_node":
			_handle_inspect_node(data)
			return true
		"simulate_key":
			_handle_simulate_key(data)
			return true
		"simulate_action":
			_handle_simulate_action(data)
			return true
		"simulate_mouse":
			_handle_simulate_mouse(data)
			return true
		"simulate_touch":
			_handle_simulate_touch(data)
			return true
		"simulate_gamepad":
			_handle_simulate_gamepad(data)
			return true
	return false


# ---------- Handlers ----------

func _handle_screenshot(data: Array) -> void:
	var viewport := get_viewport()
	if viewport == null:
		_reply(data, "error", ["no viewport"])
		return

	var tex := viewport.get_texture()
	if tex == null:
		_reply(data, "error", ["no texture"])
		return

	var img := tex.get_image()
	if img == null:
		_reply(data, "error", ["no image"])
		return

	var png_bytes := img.save_png_to_buffer()
	_reply(data, "screenshot_ready", [png_bytes, img.get_width(), img.get_height()])


func _handle_eval(data: Array) -> void:
	var code: String = str(data[1]) if data.size() > 1 else ""
	if code.is_empty():
		_reply(data, "eval_result", [false, "Missing 'code' argument"])
		return

	var script := GDScript.new()
	var src := "extends RefCounted\n\nfunc _run():\n"
	for line in code.split("\n"):
		src += "\t" + line + "\n"
	script.source_code = src

	var err := script.reload()
	if err != OK:
		_reply(data, "eval_result", [false, "GDScript parse error: %s" % error_string(err)])
		return

	var obj: Object = script.new()
	if not obj.has_method("_run"):
		_reply(data, "eval_result", [false, "Compiled script has no _run() method"])
		return

	var result = obj._run()
	_reply(data, "eval_result", [true, str(result)])


func _handle_get_tree(data: Array) -> void:
	var max_depth: int = int(data[1]) if data.size() > 1 else -1
	var include_properties: bool = bool(data[2]) if data.size() > 2 else false

	var tree := get_tree()
	if tree == null or tree.root == null:
		_reply(data, "tree_result", [false, "No scene tree"])
		return

	var serialized := _serialize_node(tree.root, 0, max_depth, include_properties)
	_reply(data, "tree_result", [true, serialized])


func _handle_inspect_node(data: Array) -> void:
	var node_path: String = str(data[1]) if data.size() > 1 else ""
	var include_methods: bool = bool(data[2]) if data.size() > 2 else false
	var include_signals: bool = bool(data[3]) if data.size() > 3 else false
	var property_filter: String = str(data[4]) if data.size() > 4 else ""

	if node_path.is_empty():
		_reply(data, "inspect_result", [false, "Missing node_path"])
		return

	var tree := get_tree()
	if tree == null or tree.root == null:
		_reply(data, "inspect_result", [false, "No scene tree"])
		return

	var node: Node = tree.root.get_node_or_null(NodePath(node_path))
	if node == null:
		_reply(data, "inspect_result", [false, "Node not found: %s" % node_path])
		return

	var info := {
		"name": node.name,
		"class": node.get_class(),
		"path": str(node.get_path()),
		"child_count": node.get_child_count(),
		"groups": [],
	}

	for g in node.get_groups():
		info["groups"].append(str(g))

	var properties := []
	for prop in node.get_property_list():
		var pname: String = prop["name"]
		if not property_filter.is_empty() and not pname.containsn(property_filter):
			continue
		if prop["usage"] & PROPERTY_USAGE_EDITOR:
			properties.append({
				"name": pname,
				"type": type_string(prop["type"]),
				"value": str(node.get(pname)),
			})
	info["properties"] = properties

	if include_methods:
		var methods := []
		for m in node.get_method_list():
			if not str(m["name"]).begins_with("_"):
				methods.append(str(m["name"]))
		info["methods"] = methods

	if include_signals:
		var signals := []
		for s in node.get_signal_list():
			signals.append(str(s["name"]))
		info["signals"] = signals

	_reply(data, "inspect_result", [true, info])


func _handle_simulate_key(data: Array) -> void:
	var keycode: int = int(data[1]) if data.size() > 1 else 0
	var pressed_any: Variant = data[2] if data.size() > 2 else null
	var echo: bool = bool(data[3]) if data.size() > 3 else false
	var shift: bool = bool(data[4]) if data.size() > 4 else false
	var ctrl: bool = bool(data[5]) if data.size() > 5 else false
	var alt: bool = bool(data[6]) if data.size() > 6 else false

	if pressed_any == null:
		_send_key(keycode as Key, true, echo, shift, ctrl, alt)
		_send_key(keycode as Key, false, false, shift, ctrl, alt)
	else:
		_send_key(keycode as Key, bool(pressed_any), echo, shift, ctrl, alt)
	_reply(data, "input_ok", ["key"])


func _handle_simulate_action(data: Array) -> void:
	var action_name: String = str(data[1]) if data.size() > 1 else ""
	var pressed_any: Variant = data[2] if data.size() > 2 else null
	var strength: float = float(data[3]) if data.size() > 3 else 1.0

	if action_name.is_empty():
		_reply(data, "input_error", ["Missing action name"])
		return
	if not InputMap.has_action(action_name):
		_reply(data, "input_error", ["Input action not found: %s" % action_name])
		return

	if pressed_any == null:
		_send_action(action_name, true, strength)
		_send_action(action_name, false, strength)
	else:
		_send_action(action_name, bool(pressed_any), strength)
	_reply(data, "input_ok", ["action"])


func _handle_simulate_mouse(data: Array) -> void:
	# data[1] = action, data[2] = pos_x, data[3] = pos_y, data[4] = button_index,
	# data[5] = scroll_delta, data[6] = drag_to_x, data[7] = drag_to_y, data[8] = double_click
	var action: String = str(data[1]) if data.size() > 1 else ""
	var pos := Vector2(float(data[2]) if data.size() > 2 else 0.0, float(data[3]) if data.size() > 3 else 0.0)
	var button: int = int(data[4]) if data.size() > 4 else MOUSE_BUTTON_LEFT
	var scroll_delta: float = float(data[5]) if data.size() > 5 else 0.0
	var drag_to := Vector2(float(data[6]) if data.size() > 6 else pos.x, float(data[7]) if data.size() > 7 else pos.y)
	var double_click: bool = bool(data[8]) if data.size() > 8 else false

	match action:
		"click":
			_send_mouse_button(pos, button, true, double_click)
			_send_mouse_button(pos, button, false, false)
		"move":
			var ev := InputEventMouseMotion.new()
			ev.position = pos
			ev.global_position = pos
			Input.parse_input_event(ev)
		"scroll":
			var ev := InputEventMouseButton.new()
			ev.position = pos
			ev.global_position = pos
			ev.button_index = MOUSE_BUTTON_WHEEL_UP if scroll_delta > 0 else MOUSE_BUTTON_WHEEL_DOWN
			ev.pressed = true
			ev.factor = absf(scroll_delta)
			Input.parse_input_event(ev)
		"drag":
			_send_mouse_button(pos, button, true, false)
			var move := InputEventMouseMotion.new()
			move.position = drag_to
			move.global_position = drag_to
			move.relative = drag_to - pos
			Input.parse_input_event(move)
			_send_mouse_button(drag_to, button, false, false)
		_:
			_reply(data, "input_error", ["Unknown mouse action: %s" % action])
			return
	_reply(data, "input_ok", ["mouse"])


func _handle_simulate_touch(data: Array) -> void:
	var action: String = str(data[1]) if data.size() > 1 else ""
	var index: int = int(data[2]) if data.size() > 2 else 0
	var pos := Vector2(float(data[3]) if data.size() > 3 else 0.0, float(data[4]) if data.size() > 4 else 0.0)

	match action:
		"press", "release":
			var ev := InputEventScreenTouch.new()
			ev.index = index
			ev.position = pos
			ev.pressed = (action == "press")
			Input.parse_input_event(ev)
		"move":
			var ev := InputEventScreenDrag.new()
			ev.index = index
			ev.position = pos
			Input.parse_input_event(ev)
		_:
			_reply(data, "input_error", ["Unknown touch action: %s" % action])
			return
	_reply(data, "input_ok", ["touch"])


func _handle_simulate_gamepad(data: Array) -> void:
	var device: int = int(data[1]) if data.size() > 1 else 0
	var kind: String = str(data[2]) if data.size() > 2 else ""  # "button" or "axis"
	var index: int = int(data[3]) if data.size() > 3 else 0
	var value: float = float(data[4]) if data.size() > 4 else 0.0

	match kind:
		"button":
			var ev := InputEventJoypadButton.new()
			ev.device = device
			ev.button_index = index as JoyButton
			ev.pressed = value > 0.5
			Input.parse_input_event(ev)
		"axis":
			var ev := InputEventJoypadMotion.new()
			ev.device = device
			ev.axis = index as JoyAxis
			ev.axis_value = value
			Input.parse_input_event(ev)
		_:
			_reply(data, "input_error", ["Unknown gamepad kind: %s" % kind])
			return
	_reply(data, "input_ok", ["gamepad"])


# ---------- Helpers ----------

func _reply(request_data: Array, message: String, payload: Array) -> void:
	var req_id: int = int(request_data[0]) if request_data.size() > 0 else 0
	var out: Array = [req_id]
	out.append_array(payload)
	EngineDebugger.send_message("catalyst:" + message, out)


func _send_key(keycode: Key, pressed: bool, echo: bool, shift: bool, ctrl: bool, alt: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = pressed
	ev.echo = echo
	ev.shift_pressed = shift
	ev.ctrl_pressed = ctrl
	ev.alt_pressed = alt
	Input.parse_input_event(ev)


func _send_action(action_name: String, pressed: bool, strength: float) -> void:
	var ev := InputEventAction.new()
	ev.action = action_name
	ev.strength = strength
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _send_mouse_button(pos: Vector2, button: int, pressed: bool, double_click: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = pos
	ev.global_position = pos
	ev.button_index = button as MouseButton
	ev.pressed = pressed
	ev.double_click = double_click
	Input.parse_input_event(ev)


func _serialize_node(node: Node, depth: int, max_depth: int, include_props: bool) -> Dictionary:
	var info := {
		"name": node.name,
		"class": node.get_class(),
		"path": str(node.get_path()),
	}
	if include_props:
		var props := {}
		for prop in node.get_property_list():
			if prop["usage"] & PROPERTY_USAGE_EDITOR and prop["usage"] & PROPERTY_USAGE_STORAGE:
				props[prop["name"]] = str(node.get(prop["name"]))
		if props.size() > 0:
			info["properties"] = props
	if max_depth < 0 or depth < max_depth:
		var children := []
		for child in node.get_children():
			children.append(_serialize_node(child, depth + 1, max_depth, include_props))
		if children.size() > 0:
			info["children"] = children
	return info
