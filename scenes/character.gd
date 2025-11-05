class_name Character
extends Node2D


@export_group("Stats")
@export var max_hp: int = 0
@export var max_cp: int = 0
@export var 	damage: int = 0
@export var speed: int = 0


enum State {
	IDLE,
	ATTACK,
	DAMAGE,
	DEATH
}
var currest_state: State = State.IDLE
@onready var animated_sprite = $AnimatedSprite2D


func set_animation(anim_name: String) -> void:
	if animated_sprite:
		animated_sprite.play(anim_name)


func get_current_animation() -> String:
	if animated_sprite:
		return animated_sprite.animation
	return ""
