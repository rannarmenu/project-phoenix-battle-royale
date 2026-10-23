extends Node

signal session_changed(role: StringName, message: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const DEFAULT_PORT: int = 24567
const DEFAULT_MAX_PLAYERS: int = 16
const MAX_SUPPORTED_PLAYERS: int = 64

var session_role: StringName = &"OFFLINE"
var status_message: String = "Offline"
var server_address: String = ""
var server_port: int = DEFAULT_PORT
var last_error: int = OK
var session_peer: ENetMultiplayerPeer

func _ready() -> void:
	_connect_multiplayer_signals()

func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

func validate_server_address(address: String) -> bool:
	var value := address.strip_edges()
	if value.is_empty() or value.length() > 253 or value.contains(" "):
		return false
	if value.is_valid_ip_address():
		return true
	if value.begins_with(".") or value.ends_with(".") or value.contains(".."):
		return false
	for character_index in range(value.length()):
		var character := value.substr(character_index, 1)
		if "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-".find(character) == -1:
			return false
	for label in value.split("."):
		if label.is_empty() or label.begins_with("-") or label.ends_with("-"):
			return false
	return true

func host_game(port: int = DEFAULT_PORT, max_players: int = DEFAULT_MAX_PLAYERS) -> int:
	if port < 1 or port > 65535 or max_players < 2 or max_players > MAX_SUPPORTED_PLAYERS:
		return _set_error(ERR_INVALID_PARAMETER, "Invalid port or player limit")
	leave_game()
	var new_peer := ENetMultiplayerPeer.new()
	var result: Error = new_peer.create_server(port, max_players - 1)
	if result != OK:
		return _set_error(result, "Could not start server on port %d" % port)
	session_peer = new_peer
	multiplayer.multiplayer_peer = session_peer
	session_role = &"SERVER"
	server_address = "0.0.0.0"
	server_port = port
	last_error = OK
	status_message = "Hosting on UDP port %d" % port
	session_changed.emit(session_role, status_message)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> int:
	var resolved_address := address.strip_edges()
	if not validate_server_address(resolved_address) or port < 1 or port > 65535:
		return _set_error(ERR_INVALID_PARAMETER, "Enter a valid server address and port")
	leave_game()
	var new_peer := ENetMultiplayerPeer.new()
	var result: Error = new_peer.create_client(resolved_address, port)
	if result != OK:
		return _set_error(result, "Could not connect to %s:%d" % [resolved_address, port])
	session_peer = new_peer
	multiplayer.multiplayer_peer = session_peer
	session_role = &"CONNECTING"
	server_address = resolved_address
	server_port = port
	last_error = OK
	status_message = "Connecting to %s:%d" % [resolved_address, port]
	session_changed.emit(session_role, status_message)
	return OK

func leave_game() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	session_peer = null
	session_role = &"OFFLINE"
	server_address = ""
	server_port = DEFAULT_PORT
	last_error = OK
	status_message = "Offline"
	session_changed.emit(session_role, status_message)

func get_status_snapshot() -> Dictionary:
	var connected_peers: int = multiplayer.get_peers().size()
	return {
		"role": session_role,
		"message": status_message,
		"address": server_address,
		"port": server_port,
		"peer_count": connected_peers,
		"is_server": multiplayer.is_server(),
		"is_online": session_role != &"OFFLINE",
		"last_error": last_error
	}

func _set_error(error_code: int, message: String) -> int:
	last_error = error_code
	status_message = message
	session_changed.emit(session_role, status_message)
	return error_code

func _on_peer_connected(peer_id: int) -> void:
	status_message = "Peer %d connected" % peer_id
	peer_joined.emit(peer_id)
	session_changed.emit(session_role, status_message)

func _on_peer_disconnected(peer_id: int) -> void:
	status_message = "Peer %d disconnected" % peer_id
	peer_left.emit(peer_id)
	session_changed.emit(session_role, status_message)

func _on_connected_to_server() -> void:
	session_role = &"CLIENT"
	status_message = "Connected to server"
	session_changed.emit(session_role, status_message)

func _on_connection_failed() -> void:
	_set_error(ERR_CANT_CONNECT, "Connection failed")
	leave_game()

func _on_server_disconnected() -> void:
	_set_error(ERR_CONNECTION_ERROR, "Server disconnected")
	leave_game()
