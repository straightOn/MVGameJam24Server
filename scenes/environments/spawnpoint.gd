class_name SpawnPoint extends Node2D

const GamePhaseResource = preload("res://shared/game_phase.gd")
const ObjectTypeResource = preload("res://shared/object_type.gd")

@onready var enemy_resource = preload("res://scenes/characters/enemy.tscn")
@export var enemy_type: ObjectTypeResource.ObjectType = ObjectTypeResource.ObjectType.Bug

signal add_enemy_event(new_enemy: Enemy, global_position: Vector2)

var time_elapsed: float = 0.0
const MAX_TIME_ELAPSED: float = 0.3
var enabled: bool = false

func _process(delta: float) -> void:
	if (!enabled):
		return
	if (!Gamemanager.can_add_enemy()):
		return
	time_elapsed += delta;
	
	if(time_elapsed > MAX_TIME_ELAPSED):
		time_elapsed = 0		
		var new_enemy: Enemy = enemy_resource.instantiate() as Enemy
		new_enemy.type = enemy_type
		var offset = Vector2(randi_range(-5, 5), randi_range(-5, 5))
		add_enemy_event.emit(new_enemy, global_position + offset)
