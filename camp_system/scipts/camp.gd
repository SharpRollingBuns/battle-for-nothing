extends Control

var player_data = {
	"level": 1,
	"hp": 100,
	"max_hp": 100,
	"cp": 20,
	"max_cp": 20
}

func _ready():
	_setup_ui()
	_load_player_data()
	_connect_buttons()
	
	# Добавляем проверку существования сцены боя
	if !ResourceLoader.exists("res://scenes/battle.tscn"):
		print("Предупреждение: Сцена боя не найдена! Создайте сцену боя в папке scenes.")

func _setup_ui():
	# Проверяем существование UI элементов
	if $PlayerInfo == null:
		print("Предупреждение: PlayerInfo контейнер не найден!")
		return
	
	# Настройка кнопок с проверкой существования
	var rest_button = $ActionButtons/RestButton
	var hunt_button = $ActionButtons/HuntButton
	
	if rest_button != null and rest_button is Button:
		rest_button.text = "Отдохнуть"
	else:
		print("Предупреждение: RestButton не найден или не является типом Button")
	
	if hunt_button != null and hunt_button is Button:
		hunt_button.text = "Охотиться"
	else:
		print("Предупреждение: HuntButton не найден или не является типом Button")
	
	# Обновляем информацию
	update_player_info()

func _load_player_data():
	# Загружаем данные игрока
	var player_level = get_meta("player_level", 1)
	var player_hp = get_meta("player_hp", 100)
	var player_max_hp = get_meta("player_max_hp", 100)
	var player_cp = get_meta("player_cp", 20)
	var player_max_cp = get_meta("player_max_cp", 20)
	
	# Сохраняем данные, если они отсутствуют
	if not Engine.get_main_loop().has_meta("player_level"):
		Engine.get_main_loop().set_meta("player_level", player_level)
		Engine.get_main_loop().set_meta("player_hp", player_hp)
		Engine.get_main_loop().set_meta("player_max_hp", player_max_hp)
		Engine.get_main_loop().set_meta("player_cp", player_cp)
		Engine.get_main_loop().set_meta("player_max_cp", player_max_cp)
	
	update_player_info()

func _connect_buttons():
	# Подключаем кнопки с проверкой
	var rest_button = $ActionButtons/RestButton
	var hunt_button = $ActionButtons/HuntButton
	
	if rest_button != null:
		rest_button.pressed.connect(_on_rest_pressed)
	
	if hunt_button != null:
		hunt_button.pressed.connect(_on_hunt_pressed)

func update_player_info():
	var player_level = get_meta("player_level", 1)
	var player_hp = get_meta("player_hp", 100)
	var player_max_hp = get_meta("player_max_hp", 100)
	var player_cp = get_meta("player_cp", 20)
	var player_max_cp = get_meta("player_max_cp", 20)
	
	# Обновляем информацию в UI
	if $PlayerInfo/LevelLabel is Label:
		$PlayerInfo/LevelLabel.text = "Уровень: %d" % player_level
	else:
		print("Предупреждение: LevelLabel не найден")
	
	if $PlayerInfo/HPLabel is Label:
		$PlayerInfo/HPLabel.text = "%d/%d" % [player_hp, player_max_hp]
	else:
		print("Предупреждение: HPLabel не найден")
	
	if $PlayerInfo/CPLabel is Label:
		$PlayerInfo/CPLabel.text = "%d/%d" % [player_cp, player_max_cp]
	else:
		print("Предупреждение: CPLabel не найден")
	
	# Обновляем прогресс-бары
	if $PlayerInfo/HPBar is ProgressBar and player_max_hp > 0:
		$PlayerInfo/HPBar.value = float(player_hp) / float(player_max_hp) * 100
	else:
		print("Предупреждение: HPBar не найден или max_hp = 0")
	
	if $PlayerInfo/CPBar is ProgressBar and player_max_cp > 0:
		$PlayerInfo/CPBar.value = float(player_cp) / float(player_max_cp) * 100
	else:
		print("Предупреждение: CPBar не найден или max_cp = 0")

func _on_rest_pressed():
	# Полное восстановление HP и CP
	var player_max_hp = get_meta("player_max_hp", 100)
	var player_max_cp = get_meta("player_max_cp", 20)
	
	Engine.get_main_loop().set_meta("player_hp", player_max_hp)
	Engine.get_main_loop().set_meta("player_cp", player_max_cp)
	
	update_player_info()
	
	# Шанс столкнуться с врагами во время отдыха
	var rest_encounter_chance = pow(get_meta("player_level", 1) / 100.0, 0.4)
	if randf() < rest_encounter_chance:
		_log("Во время отдыха на вас напали враги!")
		_start_battle()
	else:
		_log("Вы спокойно отдохнули и восстановили все силы!")

func _on_hunt_pressed():
	_start_battle()

func _start_battle():
	# Генерация партии врагов
	var enemy_party = _generate_enemy_party()
	
	# Сохраняем данные для передачи в бой
	var player_data = {
		"level": get_meta("player_level", 1),
		"hp": get_meta("player_hp", 100),
		"max_hp": get_meta("player_max_hp", 100),
		"cp": get_meta("player_cp", 20),
		"max_cp": get_meta("player_max_cp", 20)
	}
	
	# Сохраняем данные в мета-данные
	Engine.get_main_loop().set_meta("battle_player_data", player_data)
	Engine.get_main_loop().set_meta("battle_enemy_party", enemy_party)
	
	# Проверяем существование сцены боя
	var battle_scene_path = "res://scenes/battle.tscn"
	if ResourceLoader.exists(battle_scene_path):
		# Планируем смену сцены через call_deferred
		call_deferred("_change_to_battle_scene")
	else:
		_log("Ошибка: Сцена боя не найдена по пути: " + battle_scene_path)

func _change_to_battle_scene():
	# Проверяем, что мы можем безопасно изменить сцену
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/battle.tscn")
	else:
		# Если get_tree() все еще null, попробуем еще раз через таймер
		if is_instance_valid(self):
			var timer = Timer.new()
			timer.wait_time = 0.01
			timer.one_shot = true
			timer.timeout.connect(_change_to_battle_scene)
			add_child(timer)
		else:
			_log("Ошибка: Не удается переключиться на сцену боя - узел не в дереве сцен")

func _generate_enemy_party() -> Array:
	var enemy_party = []
	
	# Определяем количество врагов (1-5)
	var player_level = get_meta("player_level", 1)
	var enemy_count = min(5, 1 + int(randf() * max(2, int(floor(player_level / 10)) + 1)))
	
	# Генерируем врагов
	for i in range(enemy_count):
		var enemy_type = _get_enemy_type_by_level(player_level)
		var enemy = {
			"type": enemy_type,
			"level": player_level
		}
		enemy_party.append(enemy)
	
	return enemy_party

func _get_enemy_type_by_level(player_level: int) -> int:
	var r = randf()
	
	# Базовые вероятности
	var skeleton_prob = 0.6
	var wolf_prob = 0.25
	var boar_prob = 0.1
	var bear_prob = 0.04
	var druid_prob = 0.01
	
	# Корректируем вероятности в зависимости от уровня
	if player_level >= 5:
		skeleton_prob -= 0.2
		wolf_prob += 0.1
		boar_prob += 0.07
		bear_prob += 0.02
		druid_prob += 0.01
	
	if player_level >= 10:
		skeleton_prob -= 0.3
		wolf_prob -= 0.05
		boar_prob += 0.05
		bear_prob += 0.15
		druid_prob += 0.15
	
	# Нормализуем вероятности
	var total = skeleton_prob + wolf_prob + boar_prob + bear_prob + druid_prob
	if total > 0:
		skeleton_prob /= total
		wolf_prob /= total
		boar_prob /= total
		bear_prob /= total
		druid_prob /= total
	
	# Выбираем тип врага
	if r < skeleton_prob:
		return 0  # Скелет
	elif r < skeleton_prob + wolf_prob:
		return 1  # Волк
	elif r < skeleton_prob + wolf_prob + boar_prob:
		return 2  # Кабан
	elif r < skeleton_prob + wolf_prob + boar_prob + bear_prob:
		return 3  # Медведь
	else:
		return 4  # Друид

func _log(message: String):
	if $StatusLabel is Label:
		$StatusLabel.text = message
	print(message)
