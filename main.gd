extends Node2D

@onready var connection_handler: ConnectionHandler = %ConnectionHandler
@onready var player_resorce: Resource = preload("res://scenes/characters/player.tscn")

@onready var spawnpoint: SpawnPoint = %SpawnPoint


const ObjectTypeResource = preload("res://shared/object_type.gd")

var connected_players: Dictionary = {}
var enemies: Dictionary = {}

func _ready():
	# init events
	spawnpoint.add_enemy_event.connect(_add_enemy)
	
	connection_handler.player_connect_event.connect(_player_connect)
	connection_handler.player_disconnect_event.connect(_player_disconnect)
	connection_handler.player_move_event.connect(_player_move_event)
	connection_handler.player_join_game_event.connect(_player_join_game)
	connection_handler.create_server()
	
func _player_connect(peer_id: int):
	connection_handler.send_game_state(peer_id)

func _player_disconnect(peer_id: int):
	if (connected_players.has(peer_id)):
		remove_child(connected_players.get(peer_id))
		connected_players.erase(peer_id)
		connection_handler.object_removed(peer_id)

func _player_move_event(peer_id: int, input: Vector2):
	if (connected_players.has(peer_id)):
		(connected_players.get(peer_id) as Player).move_action(input)

func _player_join_game(peer_id: int):
	if (!connected_players.has(peer_id)):
		var initial_position: Vector2 = Vector2(50,50)
		var player: Player = player_resorce.instantiate() as Player
		connected_players[peer_id] = player
		var connected_player: Player = connected_players.get(peer_id) as Player
		connected_player.id = peer_id
		connected_player.position = initial_position
		add_child(connected_player)
		connected_player.position_changed_event.connect(connection_handler.object_position_update)
		for key in connected_players:
			var current_player: Player = connected_players[key] as Player
			connection_handler.object_created(key, ObjectTypeResource.ObjectType.Player, current_player.position)
		for key in enemies:
			var current_enemy: Enemy = enemies[key] as Enemy
			connection_handler.object_created(key, current_enemy.enemy_type, current_enemy.position)
	spawnpoint.enabled = connected_players.size() > 0

func _add_enemy(new_enemy: Enemy, global_position: Vector2):
	enemies[new_enemy.id] = new_enemy
	add_child(new_enemy)
	new_enemy.position_changed_event.connect(connection_handler.object_position_update)
	new_enemy.global_position = global_position
	connection_handler.object_created(new_enemy.id, new_enemy.enemy_type, new_enemy.position)
