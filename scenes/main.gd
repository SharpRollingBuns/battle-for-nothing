extends Node2D

func _ready():
	var player_init_res: PlayerInit = load("res://resources/player_init.tres")
	GameSession.start_new_game(player_init_res)
	
	get_tree().change_scene_to_file("res://scenes/camp_system/camp.tscn")
