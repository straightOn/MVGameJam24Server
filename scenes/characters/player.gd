class_name Player extends CharacterBase

const HP_REGENERATION: float = 0.1

var xp: int = 0
var xp_per_level: int = 100

var att_base: int = 5
var att_increase_per_level: int = 2

var maxhp_base: float = 10
var maxhp_increase_per_level: int = 2

var hp_last_regen: float = 0

var attackingEnemies: Array[Enemy] = []
var enemiesInAttackRange: Array = []

var time_since_last_hit: float = 10
var delay_for_hit: float = 1

var time_to_switch_phase: int = 10
var switch_phase_timer = 5

var kills = 0
var alive_time = 0

@onready var hp_label: Label = %Hp
@onready var phase_label: Label = %Phase
@onready var phase_timer_label: Label = %PhaseTimer

signal player_phase_switch_event(id: int, new_phase: GamePhaseResource.Phase)
signal player_phase_remaining_event(id: int, remaining: int)

var last_remaining: int

func _init():
	speed = 150
	max_hp = maxhp_base
	hp = max_hp
	type = ObjectTypeResource.ObjectType.Player
	phase = GamePhaseResource.Phase.DAY

func _ready():
	hp_label.text = str(hp)
	phase_label.text = "DAY"
		
func check_attacking_enemies() -> void:
	for body in attackingEnemies:
		if body != null && body is Enemy:
			var enemy: Enemy = body as Enemy;
			var attackPoints: float = enemy.attack_maybe(self)
			if (attackPoints > 0):
				hp -= attackPoints
				take_damage_event.emit(id, attackPoints, hp)
				hp_label.text = str(hp)
				if hp < 0:
					die()

func check_enemies_in_attacking_range() -> void:
	if time_since_last_hit > delay_for_hit && enemiesInAttackRange.size() > 0:
		time_since_last_hit = 0
		attack_event.emit(id, Vector2.ZERO)
		for body in enemiesInAttackRange:
			if body != null && body is Enemy:
				var enemy: Enemy = body as Enemy;
				var remaining_hp: float = enemy.take_damage(get_attack_strength(), global_position)
				
				if remaining_hp <= 0.0:
					xp += enemy.get_xp()
					kills += 1
					enemiesInAttackRange.erase(body)
					attackingEnemies.erase(body)
					enemy.die()

func check_if_still_alive() -> void:
	if hp > 0.0:
		pass
	else:
		die()

func _process(delta: float) -> void:
	super._process(delta)
	time_since_last_hit += delta
	alive_time += delta
	
	check_enemies_in_attacking_range()
	check_attacking_enemies()
	check_if_still_alive()
	
	hp_last_regen += delta
	
	if hp_last_regen >= 1.0:
		hp_last_regen = 0
		hp += HP_REGENERATION
		hp = min(get_max_hp(), hp)
	
	switch_phase_timer -= delta
	if (switch_phase_timer != last_remaining):
		last_remaining = switch_phase_timer
		player_phase_remaining_event.emit(id, int(switch_phase_timer))
		phase_timer_label.text = str(int(switch_phase_timer))
	
	if(switch_phase_timer < 0.0):
		switch_phase_timer = time_to_switch_phase
		switch_phase()

func get_level():
	return floor(xp / xp_per_level) + 1

func get_attack_strength():
	return att_base + ((get_level() - 1) * att_increase_per_level)

func get_max_hp():
	return maxhp_base + ((get_level() - 1) * maxhp_increase_per_level)

func switch_phase():
	match phase:
		GamePhaseResource.Phase.NIGHT:
			phase = GamePhaseResource.Phase.DAY
			phase_label.text = "DAY"
		GamePhaseResource.Phase.DAY:
			phase = GamePhaseResource.Phase.NIGHT
			phase_label.text = "NIGHT"
	player_phase_switch_event.emit(id, phase)
	
	
func _on_enemy_area_body_exited(body: Node2D) -> void:
	if is_instance_valid(body):
		attackingEnemies.erase(body)

func _on_player_area_body_exited(body: Node2D) -> void:
	if is_instance_valid(body):
		enemiesInAttackRange.erase(body)

func _on_player_area_body_entered(body: Node2D) -> void:
	if(body.is_in_group("Enemy")):
		var enemy: Enemy = body as Enemy;
		if(enemy.get_phase() == get_phase()):
			enemiesInAttackRange.append(body)

func _on_enemy_area_body_entered(body) -> void:
	if(body.is_in_group("Enemy")):
		var enemy: Enemy = body as Enemy;
		if(enemy.get_phase() == get_phase()):
			attackingEnemies.append(enemy)
