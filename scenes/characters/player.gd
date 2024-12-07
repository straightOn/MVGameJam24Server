class_name Player extends CharacterBase

const GamePhaseResource = preload("res://shared/game_phase.gd")

const HP_REGENERATION: float = 0.1

var xp: int = 0
var xp_per_level: int = 100

var att_base: int = 5
var att_increase_per_level: int = 2

var maxhp_base: float = 10
var maxhp_increase_per_level: int = 2

var hp: float = 10
var hp_last_regen: float = 0

var attackingEnemies: Array = []
var enemiesInAttackRange: Array = []

var time_since_last_hit: float = 10
var delay_for_hit: float = 1

var current_phase: GamePhaseResource.Phase = GamePhaseResource.Phase.DAY

var time_to_switch_phase: int = 60
var switch_phase_timer = 60

func _ready():
	speed = 150


func _on_enemy_area_body_entered(body: Node2D) -> void:
	if(body.is_in_group("Enemy")):
		var parent: Enemy = body.get_parent()
		
		if(parent.get_phase() == get_phase()):
			attackingEnemies.append(body)
		
		
func check_attacking_enemies() -> void:
	for body in attackingEnemies:
		if body != null:
			var parent = body.get_parent()
			
			if parent is Enemy:
				var attackPoints: float = parent.attack_maybe()
				
				hp -= attackPoints

func check_enemies_in_attacking_range() -> void:
	if time_since_last_hit > delay_for_hit && enemiesInAttackRange.size() > 0:
		time_since_last_hit = 0
		
		for body in enemiesInAttackRange:
			if body != null:
				var parent = body.get_parent()
				
				if parent is Enemy:
					var remaining_hp: float = parent.take_damage(get_attack_strength())
					
					if remaining_hp <= 0.0:
						xp += parent.get_xp()
						
						enemiesInAttackRange.erase(body)
						attackingEnemies.erase(body)
						Gamemanager.remove_enemy(parent, parent.get_enemy_type())

func check_if_still_alive() -> void:
	if hp > 0.0:
		pass
	else:		
		queue_free()

func _process(delta: float) -> void:
	super._process(delta)
	time_since_last_hit += delta
	
	check_enemies_in_attacking_range()
	check_attacking_enemies()
	check_if_still_alive()
	
	hp_last_regen += delta
	
	if hp_last_regen >= 1.0:
		hp_last_regen = 0
		hp += HP_REGENERATION
		hp = min(get_max_hp(), hp)
	
	switch_phase_timer -= delta
	
	if(switch_phase_timer < 0.0):
		switch_phase_timer = time_to_switch_phase
		switch_phase()

func _on_player_area_body_entered(body: Node2D) -> void:
	if(body.is_in_group("Enemy")):
		var parent: Enemy = body.get_parent()
		
		if(parent.get_phase() == get_phase()):
			enemiesInAttackRange.append(body)

func get_level():
	return floor(xp / xp_per_level) + 1

func get_attack_strength():
	return att_base + ((get_level() - 1) * att_increase_per_level)

func get_max_hp():
	return maxhp_base + ((get_level() - 1) * maxhp_increase_per_level)

func switch_phase():
	match current_phase:
		GamePhaseResource.Phase.NIGHT:
			current_phase = GamePhaseResource.Phase.DAY
		GamePhaseResource.Phase.DAY:
			current_phase = GamePhaseResource.Phase.NIGHT

func get_phase() -> GamePhaseResource.Phase:
	return current_phase


func _on_enemy_area_body_exited(body: Node2D) -> void:
	attackingEnemies.erase(body)


func _on_player_area_body_exited(body: Node2D) -> void:
	enemiesInAttackRange.erase(body)
