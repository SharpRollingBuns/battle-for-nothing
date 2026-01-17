class_name Skeleton
extends Enemy

func _ready():
	character_name = "Скелет"
	max_hp = 30
	max_cp = 0
	damage = 5
	speed = 8
	super._ready()

func get_action_description(target: Character) -> String:
	return "[Скелет] атакует %s и наносит %d урона!" % [target.character_name, damage]

func act(target: Character, all_enemies: Array):
	if not is_alive():
		return
	target.take_damage(damage)

func get_type_name() -> String:
	return "Скелет"

func get_base_max_hp() -> int:
	return 30

func get_base_damage() -> int:
	return 5

func get_base_speed() -> int:
	return 8

func get_enemy_color() -> Color:
	return Color(0.7, 0.7, 0.7)  # Серый
