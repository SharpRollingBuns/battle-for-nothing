extends Control

func _ready():
	# Проверяем UI элементы
	if $PlayerInfo == null:
		push_error("PlayerInfo контейнер не найден!")
		return
	
	# Инициализируем UI
	_setup_ui()
	
	# Загружаем данные игрока
	_load_player_data()
	
	# Подключаем кнопки
	_connect_buttons()
	
	# Проверяем, что PlayerData доступен
	if not PlayerData:
		push_error("PlayerData синглтон не доступен! Убедитесь, что он добавлен в AutoLoad.")

func _setup_ui():
	# Настройка кнопок с проверкой существования узлов
	var rest_button = $ActionButtons/RestButton
	var hunt_button = $ActionButtons/HuntButton
	
	if rest_button != null and rest_button is Button:
		rest_button.text = "Отдохнуть"
	else:
		push_error("RestButton не найден или не является типом Button")
	
	if hunt_button != null and hunt_button is Button:
		hunt_button.text = "Охотиться"
	else:
		push_error("HuntButton не найден или не является типом Button")
	
	# Первональное обновление информации
	update_player_info()

func _load_player_data():
	# Сначала проверяем доступность PlayerData
	if not PlayerData:
		push_error("Синглтон PlayerData не доступен!")
		return
	
	# Проверяем существование UI элементов
	var level_label = $PlayerInfo/LevelLabel
	var hp_label = $PlayerInfo/HPLabel
	var cp_label = $PlayerInfo/CPLabel
	var hp_bar = $PlayerInfo/HPBar
	var cp_bar = $PlayerInfo/CPBar
	
	if level_label == null:
		push_error("LevelLabel не подключен!")
		return
	if hp_label == null:
		push_error("HPLabel не подключен!")
		return
	if cp_label == null:
		push_error("CPLabel не подключен!")
		return
	if hp_bar == null:
		push_error("HPBar не подключен!")
		return
	if cp_bar == null:
		push_error("CPBar не подключен!")
		return
	
	# Обновляем информацию
	level_label.text = "Уровень: %d" % PlayerData.level
	hp_label.text = "%d/%d" % [PlayerData.hp, PlayerData.max_hp]
	cp_label.text = "%d/%d" % [PlayerData.cp, PlayerData.max_cp]
	
	# Обновляем прогресс-бары с проверкой на нулевые значения
	if PlayerData.max_hp > 0:
		hp_bar.value = float(PlayerData.hp) / float(PlayerData.max_hp) * 100
	if PlayerData.max_cp > 0:
		cp_bar.value = float(PlayerData.cp) / float(PlayerData.max_cp) * 100

func _connect_buttons():
	var rest_button = $ActionButtons/RestButton
	var hunt_button = $ActionButtons/HuntButton
	
	if rest_button != null:
		rest_button.pressed.connect(_on_rest_pressed)
	
	if hunt_button != null:
		hunt_button.pressed.connect(_on_hunt_pressed)

func _validate_node_connections():
	# Проверка основных узлов
	var required_nodes = [
		"ActionButtons",
		"ActionButtons/RestButton",
		"ActionButtons/HuntButton",
		"PlayerInfo",
		"PlayerInfo/LevelLabel",
		"PlayerInfo/HPLabel",
		"PlayerInfo/CPLabel",
		"PlayerInfo/HPBar",
		"PlayerInfo/CPBar",
        "StatusLabel"
	]
	
	for node_path in required_nodes:
		if get_node(node_path) == null:
			push_error("Узел не найден: " + node_path)

func update_player_info():
	var player_level = get_meta("player_level", 1)
	var player_hp = get_meta("player_hp", 100)
	var player_max_hp = get_meta("player_max_hp", 100)
	var player_cp = get_meta("player_cp", 20)
	var player_max_cp = get_meta("player_max_cp", 20)
	
	# Обновляем информацию в UI
	if $PlayerInfo/LevelLabel is Label:
		$PlayerInfo/LevelLabel.text = "Уровень: %d" % player_level
	
	if $PlayerInfo/HPLabel is Label:
		$PlayerInfo/HPLabel.text = "%d/%d" % [player_hp, player_max_hp]
	
	if $PlayerInfo/CPLabel is Label:
		$PlayerInfo/CPLabel.text = "%d/%d" % [player_cp, player_max_cp]
	
	# Обновляем прогресс-бары
	if $PlayerInfo/HPBar is ProgressBar and player_max_hp > 0:
		$PlayerInfo/HPBar.value = float(player_hp) / float(player_max_hp) * 100
	
	if $PlayerInfo/CPBar is ProgressBar and player_max_cp > 0:
		$PlayerInfo/CPBar.value = float(player_cp) / float(player_max_cp) * 100

func _on_rest_pressed():
	# Полное восстановление HP и CP
	if PlayerData:
		PlayerData.hp = PlayerData.max_hp
		PlayerData.cp = PlayerData.max_cp
		update_player_info()
		
		# Шанс столкнуться с врагами во время отдыха
		var rest_encounter_chance = pow(PlayerData.level / 100.0, 0.4)
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
	
	# Сохраняем данные для передачи в сцену боя
	if PlayerData:
		PlayerData.escape_penalty = max(0, PlayerData.escape_penalty - 1)
		# Теперь это будет работать, так как свойство объявлено
		PlayerData.current_enemy_party = enemy_party
	
	# Откладываем смену сцены
	if Engine.get_main_loop() is SceneTree and get_tree() != null:
		get_tree().create_timer(0.0).timeout.connect(_change_to_battle_scene)
	else:
		print("SceneTree недоступен. Планируем смену сцены позже.")

func _attempt_to_change_scene_later():
	# Проверяем, доступно ли дерево сцен
	if Engine.get_main_loop() is SceneTree and get_tree() != null:
		get_tree().create_timer(0.0).timeout.connect(_change_to_battle_scene)
	else:
		print("SceneTree все еще недоступен. Смена сцены невозможна.")

func _change_to_battle_scene():
	# Двойная проверка перед сменой сцены
	if get_tree() != null:
		# Убедимся, что путь к сцене правильный
		var battle_scene_path = "res://scenes/main.tscn"
		
		# Проверяем, существует ли файл сцены
		if ResourceLoader.exists(battle_scene_path):
			get_tree().change_scene_to_file(battle_scene_path)
		else:
			print("Ошибка: Сцена боя не найдена по пути: ", battle_scene_path)
	else:
		print("SceneTree недоступен. Невозможно изменить сцену.")

func _generate_enemy_party() -> Array:
	var enemy_party = []
	
	# Пример генерации партии (заглушка)
	for i in range(randi() % 4 + 1):
		var enemy = {
			"type": randi() % 5,
			"level": get_meta("player_level", 1)
		}
		enemy_party.append(enemy)
	
	return enemy_party

func _log(message: String):
	if $StatusLabel is Label:
		$StatusLabel.text = message
	print(message)


func safe_change_scene(scene_path: String):
	if get_tree() == null:
		print("Сцена еще не в дереве. Планируем смену сцены на следующий кадр.")
		get_tree().create_timer(0.0).timeout.connect(func(): safe_change_scene(scene_path))
		return
	
	if !ResourceLoader.exists(scene_path):
		print("Ошибка: Сцена не найдена по пути: " + scene_path)
		return
	
	get_tree().change_scene_to_file(scene_path)
