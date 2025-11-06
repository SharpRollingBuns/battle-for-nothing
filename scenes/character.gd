class_name Character
extends Node2D

@export_group("Stats")
@export var max_hp: int = 0
@export var max_cp: int = 0
@export var damage: int = 0
@export var speed: int = 0
@export var hp: int = 0
@export var cp: int = 0

enum State {
	IDLE,
	ATTACK,
	DAMAGE,
	DEATH
}

var current_state: State = State.IDLE
@onready var animated_sprite = $AnimatedSprite2D


func _ready():
	if max_hp <= 0:
		max_hp = 100
	if max_cp <= 0:
		max_cp = 20
	hp = max_hp
	cp = max_cp  # Инициализируем здоровье максимальным значением


func is_alive() -> bool:
	return hp > 0


func take_damage(amount: int) -> int:
	var real_damage = amount
	hp = max(0, hp - real_damage)
	
	# Если персонаж погиб, меняем состояние
	if hp <= 0:
		current_state = State.DEATH
		set_animation("death")
	else:
		current_state = State.DAMAGE
		set_animation("damage")
	
	return real_damage


func set_animation(anim_name: String) -> void:
	if animated_sprite:
		animated_sprite.play(anim_name)


func get_current_animation() -> String:
	if animated_sprite:
		return animated_sprite.animation
	return ""


func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(hp) / float(max_hp)


func get_cp_percent() -> float:
	if max_cp <= 0:
		return 0.0
	return float(cp) / float(max_cp)
