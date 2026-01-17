class_name Enemy
extends Character

# Базовый класс для всех врагов

func _ready():
	hp = max_hp
	cp = max_cp
	name = character_name
	super._ready()

func die():
	super.take_damage(hp)  # Полное обнуление HP
