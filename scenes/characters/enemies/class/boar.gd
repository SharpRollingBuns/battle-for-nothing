class_name Boar
extends Enemy

@export var cooldown: int = 0
@export var original_damage: int = 0



func get_action_description(target: Character) -> String:
	if cooldown % 2 == 0:
		return "[Кабан] бьёт копытами %s, нанося %d урона!" % [target.character_name, damage]
	else:
		return "[Кабан] злится и готовится к мощной атаке..."

func act(target: Character, all_enemies: Array):
	if not is_alive():
		return
	
	cooldown += 1
	if cooldown % 2 == 0:
		target.take_damage(damage)
