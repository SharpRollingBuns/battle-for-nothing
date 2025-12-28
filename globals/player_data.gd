extends Node

var level: int = 1
var hp: int = 100
var max_hp: int = 100
var cp: int = 20
var max_cp: int = 20
var damage: int = 10
var special_power: float = 1.0
var escape_penalty: int = 0
var consecutive_battles: int = 0


func save_current_state(player: Player):
	if player != null:
		level = player.level
		hp = player.hp
		max_hp = player.max_hp
		cp = player.cp
		max_cp = player.max_cp
		damage = player.damage
		special_power = player.special_power


func apply_to_player(player: Player):
	if player != null:
		player.level = level
		player.hp = hp
		player.max_hp = max_hp
		player.cp = cp
		player.max_cp = max_cp
		player.damage = damage
		player.special_power = special_power


func reset_for_new_game():
	level = 1
	hp = 100
	max_hp = 100
	cp = 20
	max_cp = 20
	damage = 10
	special_power = 1.0
	escape_penalty = 0
	consecutive_battles = 0
