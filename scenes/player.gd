class_name Player
extends Character

@export_group("Player Stats")
@export var special_power: float = 0
@export var cp_gain: float = 0
@export var level: int = 1
@export var xp: int = 0



# Добавляем методы для восстановления CP (маны)
func gain_cp(amount: int) -> int:
	var cp_gained = amount
	cp = min(max_cp, cp + cp_gained)
	return cp_gained



func _ready():
	hp = max_hp
	cp = max_cp


# Метод для повышения уровня
func level_up():
	level += 1
	max_hp = floor(max_hp * 1.2)
	max_cp = floor(max_cp * 1.2)
	damage = floor(damage * 1.15)
	special_power *= 1.25
	hp = max_hp
	cp = max_cp
