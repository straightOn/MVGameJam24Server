class_name Enemy extends CharacterBase

var time_since_last_hit: float = 10
var delay_for_hit: float = 1

@onready var polygon: Polygon2D = %Polygon2D

# Stats
@export var hp_base: float = 10
@export var xp: float = 1
@export var att: float = 1
@export var att_base: float = 1

var knockback_strength: int = 500
var knockback: Vector2 = Vector2.ZERO
var friction: float = 0.2

var target: Player

func _init() -> void:
	type = ObjectTypeResource.ObjectType.Bug
	phase = GamePhaseResource.Phase.DAY
	speed = 200
	id = Time.get_ticks_usec()
	hp = hp_base * pow(1.1, Gamemanager.get_wave() - 1)
	max_hp = hp
	xp = Gamemanager.get_wave()
	att = att_base * pow(1.1, Gamemanager.get_wave() - 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_since_last_hit += delta
	if knockback.length() > 1:
		velocity = knockback
		knockback = knockback.lerp(Vector2.ZERO, friction)
	else:
		if target && is_instance_valid(target):
			var direction = (target.global_position - global_position).normalized()
			move_action(direction)
		else:
			find_target()
	super._process(delta)

func find_target():
	var players = get_tree().get_nodes_in_group("Player");
	var shortest_distance = INF
	
	for node in players:
		if node is Player:
			if node.get_phase() == get_phase():
				var distance = global_position.distance_to(node.global_position)
				
				if distance < shortest_distance:
					shortest_distance = distance
					target = node

func attack_maybe(target: Player) -> float:
	if(time_since_last_hit > delay_for_hit):
		time_since_last_hit = 0
		var direction: Vector2 = global_position.direction_to(target.global_position)
		attack_event.emit(id, direction)
		return att
	
	return 0

func take_damage(damage: float, attack_position: Vector2) -> float:
	hp -= damage
		
	# Calculate knockback direction
	var knockback_direction = (global_position - attack_position).normalized()
	knockback = knockback_direction * knockback_strength
	
	take_damage_event.emit(id, damage, hp)
	return hp
	
func kill_maybe() -> void:	
	if hp <= 0.0:
		die()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if(body.is_in_group("Player")):
		if(time_since_last_hit > delay_for_hit):
			# TODO: Hit player
			
			time_since_last_hit = 0

func get_xp():
	return xp
