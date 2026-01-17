class_name Bear
extends Enemy

@export var enraged: bool = false
@export var original_damage: int = 0



func take_damage(amount: int) -> int:
	var real_damage = super.take_damage(amount)
	
	# Медведь злится при получении урона
	if not enraged and hp > 0:
		enraged = true
		damage = original_damage * 2
	
	return real_damage

func die():
	enraged = false
	damage = original_damage
	super.die()

func get_action_description(target: Character) -> String:
	if enraged:
		return "[Медведь] впадает в ярость и атакует %s, нанося %d урона!" % [target.character_name, damage]
	else:
		return "[Медведь] атакует %s, нанося %d урона!" % [target.character_name, damage]

func act(target: Character, all_enemies: Array):
	if not is_alive():
		return
	
	if enraged:
		target.take_damage(damage)
		enraged = false  # Сбрасываем ярость после атаки
	else:
		target.take_damage(damage)

func get_type_name() -> String:
	return "Медведь"

func get_base_max_hp() -> int:
	return 200

func get_base_damage() -> int:
	return 12

func get_base_speed() -> int:
	return 6

func get_enemy_color() -> Color:
	return Color(0.4, 0.3, 0.2)  # Темно-коричневый
