extends Node2D

@onready var connection_handler: ConnectionHandler = %ConnectionHandler
@onready var player_resorce: Resource = preload("res://scenes/characters/player.tscn")

@onready var spawnpoint: SpawnPoint = %SpawnPoint
@onready var spawnpoint2: SpawnPoint = %SpawnPoint2

const ObjectTypeResource = preload("res://shared/object_type.gd")

func _ready():
	# init events
	spawnpoint.add_enemy_event.connect(_add_enemy)
	spawnpoint2.add_enemy_event.connect(_add_enemy)
	
	connection_handler.player_connect_event.connect(_player_connect)
	connection_handler.player_disconnect_event.connect(_player_disconnect)
	connection_handler.player_move_event.connect(_player_move_event)
	connection_handler.player_join_game_event.connect(_player_join_game)
	connection_handler.create_server()
	
func _player_connect(peer_id: int):
	connection_handler.send_game_state(peer_id)

func _player_disconnect(peer_id: int):
	if (Gamemanager.connected_players.has(peer_id)):
		var player: Player = Gamemanager.connected_players.get(peer_id)
		Gamemanager.connected_players.erase(peer_id)
		connection_handler.object_removed(peer_id)
		remove_child(player)
		player.queue_free()
		

func _player_move_event(peer_id: int, input: Vector2):
	if (Gamemanager.connected_players.has(peer_id)):
		(Gamemanager.connected_players.get(peer_id) as Player).move_action(input)

func _player_join_game(peer_id: int):
	if (!Gamemanager.connected_players.has(peer_id)):
		create_player(peer_id)
		broadcast_game_objects(Gamemanager.connected_players)
		broadcast_game_objects(Gamemanager.enemies)

func create_player(id: int):
	var initial_position: Vector2 = Vector2(50,50)
	var player: Player = player_resorce.instantiate() as Player
	Gamemanager.connected_players[id] = player
	player.id = id
	player.position = initial_position
	add_child(player)
	player.position_changed_event.connect(connection_handler.object_position_update)
	
func broadcast_game_objects(game_objects: Dictionary):
	for key in game_objects:
		var current_game_object: GameObject = game_objects[key] as GameObject
		connection_handler.object_created(key, current_game_object.type, current_game_object.position)

func _add_enemy(new_enemy: Enemy, global_position: Vector2):
	Gamemanager.enemies[new_enemy.id] = new_enemy
	add_child(new_enemy)
	new_enemy.position_changed_event.connect(connection_handler.object_position_update)
	new_enemy.die_event.connect(_enemy_died)
	new_enemy.take_damage_event.connect(_take_damage)
	new_enemy.global_position = global_position
	connection_handler.object_created(new_enemy.id, new_enemy.type, new_enemy.position)

func _enemy_died(object: CharacterBase):
	remove_child(Gamemanager.enemies.get(object.id))
	Gamemanager.enemies.erase(object.id)
	connection_handler.object_removed(object.id)
	object.queue_free()

func _take_damage(object: CharacterBase):
	connection_handler.object_takes_damage(object.id, object.hp, object.max_hp)
