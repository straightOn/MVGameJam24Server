extends GameObject

class_name CharacterBase

var speed: float = 300
var hp: float
var max_hp: float

var last_sent_position: Vector2 = Vector2.ZERO
signal position_changed_event(id: int, position: Vector2, direction: Vector2)
signal take_damage_event(object: CharacterBase)
signal attack_event(id: int, direction: Vector2)
signal die_event(object: CharacterBase)

func move_action(direction: Vector2):
	velocity = direction * speed

func _process(delta):
	move_and_slide()
	var direction = position - last_sent_position
	direction = direction.normalized()
	if (position != last_sent_position):
		last_sent_position = position
		position_changed_event.emit(id, position, direction)

func die():
	die_event.emit(self)
