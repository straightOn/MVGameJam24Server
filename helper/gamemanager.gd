extends Node

static var _current_wave: int = 0
static var _current_status: String = "Idle" # Possible statuses: "Idle", "Ingame", "Dead"

static var _time_base: float = 5;
static var _current_time: float = _time_base;
static var _additional_time_per_wave: float = 5
static var _max_waves: int = 20

static var connected_players: Dictionary = {}
static var enemies: Dictionary = {}

signal wave_timer_updated_event(remaining: int)
signal new_wave_started_event(new_wave: int)

var last_time: int

static var bug_counter: int = 0
static var ghost_counter: int = 0

const ObjectTypeResource = preload("res://shared/object_type.gd")

func _ready() -> void:
	reset_game()

func _process(delta):	
	if (!Gamemanager.is_game_active()):
		return
	# time is für wave - man kommt automatisch in die nächste stufe
	var new_time: int = get_remaining_time(delta)
	if (new_time != last_time):
		last_time = new_time
		wave_timer_updated_event.emit(new_time)

func next_wave() -> void:
	_current_wave += 1
	_current_time = _time_base + (5 * (_current_wave - 1))
	new_wave_started_event.emit(_current_wave)
	
func get_remaining_time(delta: float) -> int:
	_current_time -= delta
	
	if(_current_time < 0):
		next_wave()
		
	return int(_current_time)

	
static func game_won() -> bool:
	return _current_wave > _max_waves
	
static func get_wave() -> int:
	return _current_wave

static func get_status() -> String:
	return _current_status

# Public setter methods
static func set_wave(wave: int) -> void:
	_current_wave = wave

static func set_status_ingame() -> void:
	_current_status = "Ingame"

static func set_status_dead() -> void:
	_current_status = "Dead"
	
static func get_max_enemies() -> int:
	return 10 * pow(1.08, _current_wave)

# Optional: Reset method to reset game data
static func reset_game() -> void:
	_current_wave = 1
	_current_status = "Idle"
	_current_time = _time_base

static func can_add_enemy() -> bool:
	return Gamemanager.enemies.size() < get_max_enemies()

static func is_game_active() -> bool:
	return Gamemanager.connected_players.size() > 0

static func get_next_type() -> ObjectTypeResource.ObjectType:
	if (bug_counter > ghost_counter):
		ghost_counter += 1
		return ObjectTypeResource.ObjectType.Ghost
	else:
		bug_counter += 1
		return ObjectTypeResource.ObjectType.Bug
