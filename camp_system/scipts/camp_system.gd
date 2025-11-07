class_name CampSystem
extends Node

@export var player_info: VBoxContainer
@export var rest_button: Button
@export var hunt_button: Button
@export var status_label: Label
@export var level_label: Label
@export var hp_label: Label
@export var cp_label: Label

var current_level: int = 1
var current_hp: int = 100
var current_cp: int = 20
var current_max_hp: int = 100
var current_max_cp: int = 20
var escape_penalty: int = 0
var last_battle_level: int = 0

# Вероятности для генерации партий
var place_probabilities = [0.1, 0.2, 0.4, 0.2, 0.1] # Для 1-5 мест соответственно
var mob_probabilities = {
	"skeleton": [0.8, 0.7, 0.5, 0.2, 0.1],
	"boar": [0.1, 0.2, 0.3, 0.4, 0.3],
	"wolf": [0.05, 0.05, 0.1, 0.2, 0.3],
	"bear": [0.03, 0.03, 0.05, 0.15, 0.2],
	"druid": [0.02, 0.02, 0.05, 0.05, 0.1]
}

func _ready():
	_update_status()
	rest_button.pressed.connect(_on_rest_pressed)
	hunt_button.pressed.connect(_on_hunt_pressed)

func _update_status():
	if status_label:
		status_label.text = "Уровень: %d\nЗдоровье: %d/%d\nМана: %d/%d" % [
			current_level,
			current_hp,
			current_max_hp,
			current_cp,
			current_max_cp
		]
	
	if level_label:
		level_label.text = "Уровень: %d" % current_level
	if hp_label:
		hp_label.text = "%d/%d" % [current_hp, current_max_hp]
	if cp_label:
		cp_label.text = "%d/%d" % [current_cp, current_max_cp]

func _on_rest_pressed():
	# Полное восстановление HP и CP ТОЛЬКО при отдыхе в лагере
	var player_max_hp = get_meta("player_max_hp", 100)
	var player_max_cp = get_meta("player_max_cp", 20)
	
	Engine.get_main_loop().set_meta("player_hp", player_max_hp)  # Полное восстановление
	Engine.get_main_loop().set_meta("player_cp", player_max_cp)  # Полное восстановление
	
	# Шанс столкнуться с врагами во время отдыха
	var rest_encounter_chance = pow(get_meta("player_level", 1) / 100.0, 0.4)
	if randf() < rest_encounter_chance:
		# Столкновение с врагами
		_log("Во время отдыха на вас напали враги!")
		_start_battle()
	else:
		# Успешный отдых
		_log("Вы спокойно отдохнули и восстановили все силы!")

func _on_hunt_pressed():
	_start_battle()

func _start_battle():
	# Генерация партии врагов
	var enemy_party = _generate_enemy_party()
	
	# Сохраняем текущий уровень для возможного побега
	last_battle_level = current_level
	
	# Передаем информацию в бой
	var player_data = {
		"level": current_level,
		"hp": current_hp,
		"max_hp": current_max_hp,
		"cp": current_cp,
		"max_cp": current_max_cp
	}
	
	# Смена сцены на бой
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	

func _generate_enemy_party() -> Array:
	# 1. Определяем количество мест в партии (от 1 до 5)
	var places = _calculate_number_of_places()
	
	# 2. Генерируем врагов для каждого места
	var enemy_party = []
	for i in range(places):
		var enemy = _generate_single_enemy(i, places, enemy_party)
		enemy_party.append(enemy)
	
	return enemy_party

func _calculate_number_of_places() -> int:
	# Получаем вероятности для каждого числа мест
	var place_weights = []
	for i in range(5):
		var weight = place_probabilities[i] * (1.0 + 0.1 * current_level)
		place_weights.append(weight)
	
	# Нормализуем вероятности
	var total_weight = 0
	for weight in place_weights:
		total_weight += weight
	
	var normalized_weights = []
	for weight in place_weights:
		normalized_weights.append(weight / total_weight)
	
	# Выбираем количество мест
	var rand_val = randf()
	var cumulative = 0.0
	for i in range(5):
		cumulative += normalized_weights[i]
		if rand_val <= cumulative:
			return i + 1
	
	return 1  # По умолчанию 1 место

func _generate_single_enemy(index: int, total_places: int, current_party: Array) -> Dictionary:
	# Учитываем правила из диздока
	# 1. Если есть скелет, то все остальные места тоже скелеты
	if current_party.size() > 0:
		var has_skeleton = false
		for enemy in current_party:
			if enemy.type == "skeleton":
				has_skeleton = true
				break
		
		if has_skeleton:
			return {"type": "skeleton", "level": current_level}
	
	# 2. Друид может быть только в партии из 5 мест
	if total_places < 5:
		mob_probabilities["druid"] = [0, 0, 0, 0, 0]
	
	# 3. Если есть волк, удваиваем вероятность других волков
	var wolf_count = 0
	for enemy in current_party:
		if enemy.type == "wolf":
			wolf_count += 1
	
	# 4. Учитываем количество мест и уровень
	var mob_weights = {}
	for mob in mob_probabilities:
		# Базовая вероятность
		var weight = mob_probabilities[mob][min(int(current_level / 20), 4)]
		
		# Правила множителей
		if mob == "druid" and total_places < 5:
			weight = 0
		elif mob == "wolf" and wolf_count > 0:
			weight *= 2
		elif mob == "skeleton" and wolf_count > 0:
			weight *= 0.5
		
		# Сила моба (1-5)
		var power = 1
		if mob == "boar": power = 2
		elif mob == "wolf": power = 3
		elif mob == "bear": power = 4
		elif mob == "druid": power = 5
		
		# Учитываем количество мест
		var place_factor = max(1, total_places - power)
		weight *= place_factor
		
		mob_weights[mob] = weight
	
	# Нормализуем вероятности
	var total_weight = 0
	for mob in mob_weights:
		total_weight += mob_weights[mob]
	
	# Выбираем врага
	var rand_val = randf() * total_weight
	var cumulative = 0.0
	for mob in mob_weights:
		cumulative += mob_weights[mob]
		if rand_val <= cumulative:
			return {"type": mob, "level": current_level}
	
	# По умолчанию возвращаем скелета
	return {"type": "skeleton", "level": current_level}

func _log(message: String):
	# Здесь можно добавить логирование в UI
	print(message)
