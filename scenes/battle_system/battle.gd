class_name BattleScene
extends Node2D

@onready var battle_system := $BattleSystem
@onready var battle_ui := $CanvasLayer/BattleUI


func load_party(player_state: PlayerState, enemy_party: Array[Enemy]):
	battle_system.players[0] = Player.new()
	battle_system.players[0].apply_state(player_state)
	battle_system.enemies = enemy_party
