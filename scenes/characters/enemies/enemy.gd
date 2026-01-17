class_name Enemy
extends Character

# Базовый класс для всех врагов

func _ready():
	super._ready()

func die():
	super.take_damage(hp)  # Полное обнуление HP
