class_name WolfEnemy
extends Enemy



func get_action_description(target: Character) -> String:
	return "[Волк] нападает на %s, нанося %d урона!" % [target.character_name, damage]

func act(target: Character, all_enemies: Array):
	if not is_alive():
		return
	target.take_damage(damage)

func get_type_name() -> String:
	return "Волк"

func get_base_max_hp() -> int:
	return 25

func get_base_damage() -> int:
	return 8

func get_base_speed() -> int:
	return 18

func get_enemy_color() -> Color:
	return Color(0.5, 0.5, 0.4)  # Серо-коричневый
