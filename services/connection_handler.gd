class_name ConnectionHandler extends RpcBase

signal player_connect_event(peer_id: int)
signal player_disconnect_event(peer_id: int)
signal player_move_x_event(peer_id: int, input: float)
signal player_move_y_event(peer_id: int, input: float)
signal player_move_event(peer_id: int, input: Vector2)
signal player_join_game_event(peer_id: int)

var active_connections: Array[int] = []

func create_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(ConnectionConstants.PORT, ConnectionConstants.MAX_CONNECTIONS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(self._on_peer_connected)
	multiplayer.peer_disconnected.connect(self._on_peer_disconnected)
	print_debug("server started on port ", ConnectionConstants.PORT)

func _on_peer_connected(peer_id):
	print_debug("connected: ", peer_id)
	active_connections.append(peer_id)
	player_connect_event.emit(peer_id)
	
func _on_peer_disconnected(peer_id):
	print_debug("disconnected: ", peer_id)
	active_connections.erase(peer_id)
	player_disconnect_event.emit(peer_id)
	
func object_created(id: int, type: ObjectTypeResource.ObjectType, initial_position: Vector2):
	print_debug("Object created.")
	for connection in active_connections:
		rpc_id(connection, "receive_object_created", id, type, initial_position)

func object_removed(id: int):
	print_debug("Object removed.")
	for connection in active_connections:
		rpc_id(connection, "receive_object_removed", id)
	
func object_position_update(id: int, position: Vector2, direction: Vector2):
	print_debug("Updating Object position.")
	for connection in active_connections:
		rpc_id(connection, "receive_object_position_update", id, position, direction)

func send_game_state(peer_id: int):
	rpc_id(peer_id, "receive_game_state", active_connections.size(), ConnectionConstants.MAX_CONNECTIONS)

@rpc("any_peer")
func join_game():
	super.join_game()
	var sender_id = multiplayer.get_remote_sender_id()
	self.player_join_game_event.emit(sender_id)

@rpc("any_peer")
func move_action(direction: Vector2):
	super.move_action(direction)
	var sender_id = multiplayer.get_remote_sender_id()
	self.player_move_event.emit(sender_id, direction)
	
