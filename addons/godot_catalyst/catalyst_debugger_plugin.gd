@tool
class_name CatalystDebuggerPlugin
extends EditorDebuggerPlugin
## Editor-side bridge to the running game. Sends messages over Godot's
## debug channel and collects responses captured from the game via the
## catalyst_game_agent autoload.

signal response_received(message: String, data: Array)

var _next_req_id: int = 1
var _responses: Dictionary = {}  # req_id -> {message, data}


func _has_capture(prefix: String) -> bool:
	return prefix == "catalyst"


func _capture(message: String, data: Array, _session_id: int) -> bool:
	# Messages arrive as "catalyst:<action>". Strip the prefix.
	var short := message.trim_prefix("catalyst:")
	var req_id: int = data[0] if data.size() > 0 and typeof(data[0]) == TYPE_INT else 0
	if req_id > 0:
		_responses[req_id] = {"message": short, "data": data}
	response_received.emit(short, data)
	return true


func next_request_id() -> int:
	var id := _next_req_id
	_next_req_id += 1
	return id


func has_active_session() -> bool:
	for session in get_sessions():
		if session and session.is_active():
			return true
	return false


func send(message: String, data: Array) -> void:
	for session in get_sessions():
		if session and session.is_active():
			session.send_message("catalyst:" + message, data)


func take_response(req_id: int) -> Variant:
	if _responses.has(req_id):
		var r: Dictionary = _responses[req_id]
		_responses.erase(req_id)
		return r
	return null


## Sends a message with a freshly-allocated req_id (prepended to data) and
## awaits a matching response from the game. Returns the response dict
## {message, data} or null on timeout. Caller must `await` this.
func request(message: String, payload: Array, timeout_ms: int = 3000) -> Variant:
	if not has_active_session():
		return null
	var req_id := next_request_id()
	var args: Array = [req_id]
	args.append_array(payload)
	send(message, args)

	var deadline := Time.get_ticks_msec() + timeout_ms
	var tree := Engine.get_main_loop() as SceneTree
	while Time.get_ticks_msec() < deadline:
		var resp: Variant = take_response(req_id)
		if resp != null:
			return resp
		if tree:
			await tree.process_frame
		else:
			await Engine.get_main_loop()
	return null
