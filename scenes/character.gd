class_name Character
extends Node2D

@export_group("Stats")
@export var max_hp: int = 100
@export var max_cp: int = 20
@export var damage: int = 0
@export var speed: int = 10
@export var character_name: String = "Unknown"  # Основное имя персонажа

enum State {
	IDLE,
	ATTACK,
	DAMAGE,
	DEATH
}

var current_state: State = State.IDLE
@onready var animated_sprite = $AnimatedSprite2D

var hp: int = 0
var cp: int = 0

func _ready():
	# Устанавливаем имя узла, если оно стандартное
	if name == "Character":
		name = character_name
	else:
		# Если имя узла уже задано, используем его
		character_name = name
	
	hp = max_hp
	cp = max_cp

func take_damage(amount: int) -> int:
	var real_damage = amount
	hp = max(0, hp - real_damage)
	return real_damage

func is_alive() -> bool:
	return hp > 0

func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)

func get_cp_percent() -> float:
	if max_cp <= 0:
		return 0.0
	return float(cp) / float(max_cp)

func set_animation(anim_name: String) -> void:
	if animated_sprite:
		animated_sprite.play(anim_name)

func get_current_animation() -> String:
	if animated_sprite:
		return animated_sprite.animation
	return ""
