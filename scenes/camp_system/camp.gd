class_name Camp
extends Node2D

@export var camp_ui: CampUI
@export var camp_system: CampSystem
# @onready var battle_scene := load("res://scenes/battle_system/battle.tscn") as PackedScene


func _ready():
	assert(camp_ui != null, "CampUI does not exist")
	assert(camp_system != null, "CampSystem does not exist")
	update_player_info()


func update_player_info():
	camp_ui.update_player_info(GameSession.player_state)


func _on_camp_ui_hunt_button_pressed() -> void:
	# _start_battle()
	pass


func _on_camp_ui_rest_button_pressed() -> void:
	# Забираем значение
	var player_state = GameSession.player_state
	
	# Шанс столкнуться с врагами во время отдыха
	var rest_encounter_chance = pow(player_state.level / 100.0, 0.4)
	
	if randf() < rest_encounter_chance:
		_log("Во время отдыха на вас напали враги!")
		# Частично пополняем здоровье
		player_state.hp = int((player_state.max_hp - player_state.hp) / 2.0)
		player_state.cp = int((player_state.max_cp - player_state.cp) / 2.0)
		# _start_battle()
	else:
		# Полностью пополняем здоровье
		player_state.hp = player_state.max_hp
		player_state.cp = player_state.max_cp
		_log("Вы спокойно отдохнули и восстановили все силы!")
	
	# Инициализируем новые данные назад
	GameSession.player_state = player_state
	update_player_info()


# func _start_battle():
	# Генерация партии врагов
	# var enemy_party = camp_system.generate_enemy_party()
	# var battle := battle_scene.instantiate()
	# battle.load_party(GameSession.player_state, enemy_party)
	
	# Меняем сцену (безопаснее, чем было ранее)
	# get_tree().root.add_child(battle)
	# if get_tree().current_scene:
		# get_tree().current_scene.queue_free()
	# get_tree().current_scene = battle


func _log(message: String):
	camp_ui.write_log(message)
	print(message)
