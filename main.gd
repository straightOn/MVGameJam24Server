extends Node2D

@onready var connection_handler: ConnectionHandler = %ConnectionHandler
@onready var player_resorce: Resource = preload("res://scenes/characters/player.tscn")

@onready var spawnpoint: SpawnPoint = %SpawnPoint
@onready var spawnpoint2: SpawnPoint = %SpawnPoint2

@onready var game_status_label: Label = %StatusLabel

const ObjectTypeResource = preload("res://shared/object_type.gd")

static var connected_players: Dictionary = {}
static var enemies: Dictionary = {}

func _ready():
	# spawn-events
	spawnpoint.add_enemy_event.connect(_add_enemy)
	spawnpoint2.add_enemy_event.connect(_add_enemy)
	# wave-events
	Gamemanager.wave_timer_updated_event.connect(connection_handler.update_wave_timer)
	Gamemanager.new_wave_started_event.connect(connection_handler.new_wave_started)
	# connection events
	connection_handler.player_connect_event.connect(_player_connect)
	connection_handler.player_disconnect_event.connect(_player_disconnect)
	connection_handler.player_move_event.connect(_player_move_event)
	connection_handler.player_join_game_event.connect(_player_join_game)
	connection_handler.create_server()
	
func _player_connect(peer_id: int):
	connection_handler.send_game_state(peer_id)

func _player_disconnect(peer_id: int):
	if (connected_players.has(peer_id)):
		var player: Player = connected_players.get(peer_id)
		connected_players.erase(peer_id)
		remove_object(player)

func _player_move_event(peer_id: int, input: Vector2):
	if (connected_players.has(peer_id)):
		(connected_players.get(peer_id) as Player).move_action(input)

func _player_join_game(peer_id: int, name: String):
	if (!connected_players.has(peer_id)):
		connection_handler.new_wave_started(Gamemanager._current_wave)
		connection_handler.update_wave_timer(Gamemanager._current_time)
		create_player(peer_id, name)
		broadcast_game_objects(connected_players)
		broadcast_game_objects(enemies)

func create_player(id: int, player_name: String):
	var initial_position: Vector2 = Vector2(50,50)
	var player: Player = player_resorce.instantiate() as Player
	connected_players[id] = player
	player.id = id
	player.label = player_name
	player.position = initial_position
	# connect events
	player.position_changed_event.connect(connection_handler.object_position_update)
	player.attack_event.connect(connection_handler.object_attacks)
	player.take_damage_event.connect(connection_handler.object_takes_damage)
	player.player_phase_remaining_event.connect(connection_handler.player_phase_remaining)
	player.player_phase_switch_event.connect(connection_handler.player_phase_switch)
	player.die_event.connect(_player_died)
	# add object
	add_object(player)
	
func broadcast_game_objects(game_objects: Dictionary):
	for key in game_objects:
		var current_game_object: CharacterBase = game_objects[key] as CharacterBase
		connection_handler.object_created(key, current_game_object.type, current_game_object.position, current_game_object.hp, current_game_object.max_hp,  current_game_object.label)

func _add_enemy(new_enemy: Enemy, global_position: Vector2):
	enemies[new_enemy.id] = new_enemy
	new_enemy.position_changed_event.connect(connection_handler.object_position_update)
	new_enemy.die_event.connect(_enemy_died)
	new_enemy.take_damage_event.connect(connection_handler.object_takes_damage)
	new_enemy.attack_event.connect(connection_handler.object_attacks)
	new_enemy.global_position = global_position
	add_object(new_enemy)

func _enemy_died(object: CharacterBase):
	remove_object(object)
	enemies.erase(object.id)

func _player_died(player: Player):
	connection_handler.game_over(player.id, player.kills, int(player.alive_time))
	remove_object(player)
	connected_players.erase(player.id)

func remove_object(object):
	connection_handler.object_removed(object.id)
	object.queue_free()
	if object is Player:
		Gamemanager.player_count -= 1
	if object is Enemy:
		Gamemanager.enemy_count -= 1
	check_state()

func add_object(object: CharacterBase):
	connection_handler.object_created(object.id, object.type, object.position, object.hp, object.max_hp, object.label)
	add_child(object)
	if object is Player:
		Gamemanager.player_count += 1
	if object is Enemy:
		Gamemanager.enemy_count += 1
	check_state()

func check_state():
	if Gamemanager.player_count > 0:
		Gamemanager.set_active()
	else:
		# clear all enemies
		for node in get_children():
			if node is Enemy:
				node.queue_free()
		enemies.clear()
		Gamemanager.reset_game_state()
	if Gamemanager.is_game_active():
		game_status_label.text = "ACTIVE"
	else:
		game_status_label.text = "PAUSED"
