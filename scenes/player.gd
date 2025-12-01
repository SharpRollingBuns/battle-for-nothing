class_name Player
extends Character

@export var special_power: float = 1.0
@export var cp_gain: float = 0
@export var level: int = 1
@export var xp: int = 0
@export var is_defending: bool = false


func _ready():
	# Устанавливаем имя узла, если оно стандартное
	if name == "Player":
		name = character_name
	# Инициализируем характеристики
	cp = max_cp
	super._ready()

func take_damage(amount: int) -> int:
	var real_dmg = amount
	if is_defending:
		real_dmg *= 0.25
	
	hp = max(0, hp - real_dmg)
	
	# Восстанавливаем CP за полученный урон
	cp = min(max_cp, cp + int(real_dmg * 0.1))
	
	return real_dmg

func deal_damage(target: Character, amount: float):
	# Восстанавливаем CP за нанесенный урон
	cp = min(max_cp, cp + int(amount * 0.1))
	target.take_damage(amount)

func level_up():
	level += 1
	max_hp = floor(10 * pow(level, 1.7) + level)
	max_cp = floor(2 * pow(level, 1.3) + level)
	damage = floor(pow(level, 1.6) + level)
	special_power = pow(level, 2)
	hp = max_hp
	cp = max_cp
	is_defending = false
