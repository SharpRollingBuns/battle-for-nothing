class_name Wolf
extends Enemy



func get_action_description(target: Character) -> String:
	return "[Волк] нападает на %s, нанося %d урона!" % [target.character_name, damage]

func act(target: Character, all_enemies: Array):
	if not is_alive():
		return
	target.take_damage(damage)
