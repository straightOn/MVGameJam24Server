class_name Enemy extends CharacterBase

const GamePhaseResource = preload("res://shared/game_phase.gd")
const ObjectTypeResource = preload("res://shared/object_type.gd")

var time_since_last_hit: float = 10
var delay_for_hit: float = 1

# Stats
@export var hp: float = 10
@export var hp_base: float = 10
@export var xp: float = 1
@export var att: float = 1
@export var att_base: float = 1

@export var enemy_type: ObjectTypeResource.ObjectType = ObjectTypeResource.ObjectType.Bug
@export var enemy_phase: GamePhaseResource.Phase = GamePhaseResource.Phase.DAY

var target: Player

func _ready() -> void:
	id = Time.get_ticks_usec()
	hp = hp_base * pow(1.1, Gamemanager.get_wave() - 1)
	xp = Gamemanager.get_wave()
	att = att_base * pow(1.1, Gamemanager.get_wave() - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
	time_since_last_hit += delta
	find_target()
	
	if target:
		var direction = (target.global_position - global_position).normalized()
		move_action(direction)
	#if hp <= 0.0:
		#queue_free()

func find_target():
	var players = get_tree().get_nodes_in_group("Players");
	var shortest_distance = INF
	
	for node in players:
		if node is Player:
			if node.get_phase() == enemy_phase:
				var distance = global_position.distance_to(node.global_position)
				
				if distance < shortest_distance:
					shortest_distance = distance
					target = node

func get_enemy_type():
	return enemy_type

func attack_maybe() -> float:
	if(time_since_last_hit > delay_for_hit):
		time_since_last_hit = 0
		return att
	
	return 0

func take_damage(damage: float) -> float:
	hp -= damage
	
	var reverse_direction = -(velocity).normalized()
	move_action(reverse_direction)
	
	return hp
	
func kill_maybe() -> void:	
	if hp <= 0.0:
		queue_free()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.is_in_group("Players")):
		if(time_since_last_hit > delay_for_hit):
			# TODO: Hit player
			
			time_since_last_hit = 0

func get_xp():
	return xp

func get_phase():
	return enemy_phase
