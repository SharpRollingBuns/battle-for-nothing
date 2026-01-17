class_name Character
extends Node2D

@export_group("Stats")
@export var character_name: String = "Unknown"
@export var max_hp: int = 100
@export var max_cp: int = 20
@export var damage: int = 0
@export var speed: int = 10

@onready var animated_sprite = $AnimatedSprite2D

var hp: int = 0
var cp: int = 0


func _ready():
	hp = max_hp
	cp = max_cp
	name = character_name
	

func take_damage(amount: int) -> int:
	var damage_taken = amount
	hp = max(0, hp - damage_taken)
	return damage_taken


func deal_damage(target: Character, amount: int):
	target.take_damage(amount)


func is_alive() -> bool:
	return hp > 0
