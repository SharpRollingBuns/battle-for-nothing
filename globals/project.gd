extends Node

func _ready():
	# Инициализируем мета-данные
	if not Engine.get_main_loop().has_meta("player_level"):
		Engine.get_main_loop().set_meta("player_level", 1)
		Engine.get_main_loop().set_meta("player_hp", 100)
		Engine.get_main_loop().set_meta("player_max_hp", 100)
		Engine.get_main_loop().set_meta("player_cp", 20)
		Engine.get_main_loop().set_meta("player_max_cp", 20)
