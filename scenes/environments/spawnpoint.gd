class_name SpawnPoint extends Node2D

@onready var enemy_resource = preload("res://scenes/characters/enemy.tscn")
@export var enemy_type: Gamemanager.ENEMY_TYPE = Gamemanager.ENEMY_TYPE.BUG

signal add_enemy_event(new_enemy: Enemy, global_position: Vector2)

var time_elapsed: float = 0.0
const MAX_TIME_ELAPSED: float = 0.3
var enabled: bool = false

func _process(delta: float) -> void:
	if (!enabled):
		return
	time_elapsed += delta;
	
	if(time_elapsed > MAX_TIME_ELAPSED && Gamemanager.can_add_enemy(enemy_type)):
		time_elapsed = 0
		var new_enemy = null
		
		match enemy_type:
			Gamemanager.ENEMY_TYPE.BUG:
				new_enemy = enemy_resource.instantiate()
			Gamemanager.ENEMY_TYPE.GHOST:
				# need to init with other data
				new_enemy = enemy_resource.instantiate()
				
		if new_enemy != null:
			#Gamemanager.add_enemy(new_enemy, enemy_type)
			#add_child(new_enemy)
			add_enemy_event.emit(new_enemy, global_position)
