class_name BattleUI
extends Control

@export var battle_system: BattleSystem
@export var hp_bar: ProgressBar
@export var cp_bar: ProgressBar
@export var action_panel: VBoxContainer
@export var target_panel: HBoxContainer
@export var enemy_info_panel: GridContainer
@export var battle_log: RichTextLabel
@export var turn_counter: Label
@export var hp_label: Label
@export var cp_label: Label

var current_action: String = ""
var current_target: Character = null
var player: Player = null

func _ready():
	var missing_nodes = []
	if hp_bar == null: missing_nodes.append("hp_bar")
	if cp_bar == null: missing_nodes.append("cp_bar")
	if action_panel == null: missing_nodes.append("action_panel")
	if target_panel == null: missing_nodes.append("target_panel")
	if enemy_info_panel == null: missing_nodes.append("enemy_info_panel")
	if battle_log == null: missing_nodes.append("battle_log")
	if turn_counter == null: missing_nodes.append("turn_counter")
	if hp_label == null: missing_nodes.append("hp_label")
	if cp_label == null: missing_nodes.append("cp_label")
	
	if !missing_nodes.is_empty():
		var error_msg = "Не подключены следующие узлы UI: " + ", ".join(missing_nodes)
		push_error(error_msg)
		return
	
	target_panel.visible = false
	
	# Проверяем, подключен ли battle_system
	if battle_system:
		# Проверяем, не подключен ли уже сигнал
		if battle_system.turn_started.is_connected(_on_turn_started):
			battle_system.turn_started.disconnect(_on_turn_started)
		if battle_system.battle_ended.is_connected(_on_battle_ended):
			battle_system.battle_ended.disconnect(_on_battle_ended)
		
		# Подключаем сигналы
		battle_system.turn_started.connect(_on_turn_started)
		battle_system.battle_ended.connect(_on_battle_ended)
	
	# Находим игрока
	if battle_system != null && battle_system.players.size() > 0:
		player = battle_system.players[0]
		_update_interface()
	else:
		push_error("Игрок не найден в системе боя")
		return
	
	# Подключаем кнопки действий
	_connect_action_buttons()
	
	# Инициализация лога боя
	if battle_log:
		battle_log.clear()
		battle_log.add_text("Битва началась!")
	
	# Инициализация счетчика ходов
	if turn_counter:
		turn_counter.text = "Ход: 1"

func _connect_action_buttons():
	var button_names = ["AttackButton", "AbilityButton", "DefendButton", "EscapeButton"]
	
	for button_name in button_names:
		if action_panel.has_node(button_name):
			var button = action_panel.get_node(button_name)
			if button != null:
				# Подключаем сигнал pressed к соответствующему методу
				match button_name:
					"AttackButton":
						button.pressed.connect(_on_attack_pressed)
					"AbilityButton":
						button.pressed.connect(_on_ability_pressed)
					"DefendButton":
						button.pressed.connect(_on_defend_pressed)
					"EscapeButton":
						button.pressed.connect(_on_escape_pressed)
				
				# Добавляем проверку состояния для визуального отключения
				button.disabled = false
			else:
				push_warning("Кнопка %s не найдена" % button_name)
		# Не выводим ошибку, если кнопка не найдена - это допустимо

func _update_interface():
	if player == null:
		return
	
	# Обновляем прогрессбары
	hp_bar.value = float(player.get_hp_percent() * 100)
	cp_bar.value = float(player.get_cp_percent() * 100)
	
	# Обновляем текстовые метки
	hp_label.text = "%d/%d" % [player.hp, player.max_hp]
	cp_label.text = "%d/%d" % [player.cp, player.max_cp]
	
	# Обновляем информацию о врагах
	_update_enemy_info()
	
	# Проверяем, активны ли кнопки
	_update_button_states()

func _update_enemy_info():
	# Очищаем предыдущую информацию
	for child in enemy_info_panel.get_children():
		child.queue_free()
	
	# Добавляем информацию о каждом живом враге
	var enemy_count = 0
	for enemy in battle_system.enemies:
		if is_instance_valid(enemy) && enemy.is_alive():
			var enemy_label = Label.new()
			enemy_label.text = "%s: %d/%d HP" % [enemy.name, enemy.hp, enemy.max_hp]
			enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			enemy_label.size_flags_horizontal = SIZE_EXPAND_FILL
			enemy_info_panel.add_child(enemy_label)
			enemy_count += 1
	
	# Если нет живых врагов, показываем сообщение
	if enemy_count == 0:
		var no_enemies = Label.new()
		no_enemies.text = "Врагов больше нет!"
		no_enemies.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_enemies.size_flags_horizontal = SIZE_EXPAND_FILL
		enemy_info_panel.add_child(no_enemies)

func _update_button_states():
	# Проверяем, активен ли игрок
	var is_player_turn = battle_system.battle_active && player != null
	
	# Обновляем активность кнопок
	if action_panel:
		for button in action_panel.get_children():
			if button is Button:
				button.disabled = !is_player_turn

func _show_targets(only_enemies: bool = true):
	# Очищаем панель
	for child in target_panel.get_children():
		child.queue_free()
	
	# Показываем возможных целей
	if only_enemies:
		var count = 0
		for enemy in battle_system.enemies:
			if is_instance_valid(enemy) && enemy.is_alive():
				var button = Button.new()
				button.text = enemy.name
				button.name = "Target_%d" % count
				button.pressed.connect(Callable(self, "_on_target_selected").bind(enemy))
				target_panel.add_child(button)
				count += 1
	else:
		# Добавляем возможность выбрать себя для лечения
		var self_button = Button.new()
		self_button.text = "Себя"
		self_button.pressed.connect(Callable(self, "_on_target_selected").bind(player))
		target_panel.add_child(self_button)
		
		# Добавляем врагов
		var count = 0
		for enemy in battle_system.enemies:
			if is_instance_valid(enemy) && enemy.is_alive():
				var button = Button.new()
				button.text = enemy.name
				button.name = "Target_%d" % count
				button.pressed.connect(Callable(self, "_on_target_selected").bind(enemy))
				target_panel.add_child(button)
				count += 1
	
	# Показываем панель выбора целей
	action_panel.visible = false
	target_panel.visible = true

func _log_action(text: String, action_type = "normal"):
	if battle_log:
		var color = Color.WHITE
		match action_type:
			"player":
				color = Color.GREEN
			"enemy":
				color = Color.RED
			"system":
				color = Color.YELLOW
		
		battle_log.push_color(color)
		battle_log.add_text("\n" + text)
		battle_log.pop()
		
		battle_log.scroll_to_line(battle_log.get_line_count() - 1)

func _on_turn_started(combatant: Character):
	_update_interface()
	
	if turn_counter:
		var current_turn = (battle_system.current_index + 1)
		turn_counter.text = "Ход: %d" % current_turn
	
	if is_instance_valid(combatant) && combatant is Player:
		# Ход игрока - показываем панель действий
		action_panel.visible = true
		target_panel.visible = false
		_log_action("Ваш ход!", "player")
	elif is_instance_valid(combatant) && combatant is Enemy:
		# Ход врага - скрываем панель действий
		action_panel.visible = false
		target_panel.visible = false
		_log_action("%s ходит..." % combatant.name, "enemy")
		
		# Имитируем задержку перед ходом врага
		get_tree().create_timer(1.0).timeout.connect(_handle_enemy_turn)

func _handle_enemy_turn():
	if !battle_system.battle_active:
		return
	
	if battle_system.combat_queue.size() == 0:
		return
	
	# Проверяем текущий индекс и очередь
	if battle_system.current_index >= battle_system.combat_queue.size():
		battle_system.current_index = 0
	
	var current_combatant = battle_system.combat_queue[battle_system.current_index]
	
	# Проверяем, что объект существует перед проверкой типа
	if is_instance_valid(current_combatant) && current_combatant is Enemy:
		var enemy = current_combatant as Enemy
		
		# Получаем описание действия перед выполнением
		var action_description = enemy.get_action_description(player)
		
		# Выполняем действие врага
		enemy.act(player, battle_system.enemies)
		
		# Логируем действие
		_log_action(action_description, "enemy")
		
		# Проверка смерти игрока
		if player.hp <= 0:
			player.hp = 0
			_update_interface()
			battle_system.end_battle(false)
			return
		
		# Восстановление CP за полученный урон
		var damage_taken = enemy.damage
		var cp_gained = int(floor(damage_taken * 0.1))
		if cp_gained > 0:
			player.cp = min(player.max_cp, player.cp + cp_gained)
			_log_action("Вы получили %d CP за полученный урон!" % cp_gained, "system")
		
		# Обновляем интерфейс
		_update_interface()
		
		# Переходим к следующему ходу
		battle_system.next_turn()

func _on_battle_ended(winner_is_player: bool):
	if winner_is_player:
		# Сохраняем данные игрока в синглтон
		if PlayerData:
			PlayerData.level = player.level
			PlayerData.hp = player.hp
			PlayerData.max_hp = player.max_hp
			PlayerData.cp = player.cp
			PlayerData.max_cp = player.max_cp
			PlayerData.damage = player.damage
			PlayerData.special_power = player.special_power
			
			# Увеличиваем счетчик боев подряд
			PlayerData.consecutive_battles += 1
	else:
		if battle_system.escape_active and PlayerData:
			PlayerData.escape_penalty = 2
	
	# Показываем соответствующие панели
	if winner_is_player:
		_show_victory_options()
	else:
		_show_defeat_options()

func _show_victory_options():
	# Скрываем текущие панели
	action_panel.visible = false
	target_panel.visible = false
	
	# Создаем панель выбора
	var victory_panel = _create_victory_panel()
	add_child(victory_panel)

func _create_victory_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "VictoryPanel"
	panel.position = Vector2(300, 200)  # Центрируем в окне
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	var title = Label.new()
	title.text = "ПОБЕДА!"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var stats_label = Label.new()
	stats_label.text = "Уровень: %d\nЗдоровье: %d/%d\nМана: %d/%d" % [
		player.level,
		player.hp,
		player.max_hp,
		player.cp,
		player.max_cp
	]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)
	
	var continue_button = Button.new()
	continue_button.text = "Продолжить охоту"
	continue_button.size_flags_horizontal = SIZE_EXPAND_FILL
	continue_button.pressed.connect(_on_continue_hunting_pressed)
	vbox.add_child(continue_button)
	
	var return_button = Button.new()
	return_button.text = "Вернуться в лагерь"
	return_button.size_flags_horizontal = SIZE_EXPAND_FILL
	return_button.pressed.connect(_on_return_to_camp_pressed)
	vbox.add_child(return_button)
	
	panel.add_child(vbox)
	return panel

func _show_defeat_options():
	# Скрываем текущие панели
	action_panel.visible = false
	target_panel.visible = false
	
	# Создаем панель выбора
	var defeat_panel = _create_defeat_panel()
	add_child(defeat_panel)

func _create_defeat_panel() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.name = "DefeatPanel"
	panel.position = Vector2(300, 200)  # Центрируем в окне
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	var title = Label.new()
	title.text = "ПОРАЖЕНИЕ"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var message = Label.new()
	message.text = "Вы проиграли этот бой.\nВас вернуло в лагерь с половиной здоровья и маны."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(message)
	
	var return_button = Button.new()
	return_button.text = "Вернуться в лагерь"
	return_button.size_flags_horizontal = SIZE_EXPAND_FILL
	return_button.pressed.connect(_on_return_to_camp_pressed)
	vbox.add_child(return_button)
	
	panel.add_child(vbox)
	return panel

func _on_continue_hunting_pressed():
	# Сохраняем текущее состояние игрока
	var player_data = {
		"level": player.level,
		"hp": player.hp,        # Текущее здоровье, а не максимальное
		"max_hp": player.max_hp,
		"cp": player.cp,        # Текущая мана, а не максимальная
		"max_cp": player.max_cp
	}
	
	# Удаляем текущих врагов из сцены
	for enemy in battle_system.enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	# Очищаем старые данные
	battle_system.enemies.clear()
	battle_system.combat_queue.clear()
	
	# Генерируем новую партию врагов
	var new_enemies = battle_system.generate_new_enemy_party(player.level)
	
	# Добавляем новых врагов в систему боя и в сцену
	var enemies_container = get_tree().current_scene.get_node("EnemiesContainer")
	if enemies_container == null:
		# Создаем контейнер, если его нет
		enemies_container = Node2D.new()
		enemies_container.name = "EnemiesContainer"
		get_tree().current_scene.add_child(enemies_container)
	
	for enemy in new_enemies:
		battle_system.enemies.append(enemy)
		enemies_container.add_child(enemy)
	
	# Обновляем очередь боя
	battle_system.combat_queue.append(player)
	for enemy in battle_system.enemies:
		battle_system.combat_queue.append(enemy)
	
	# Сортируем по скорости
	battle_system.combat_queue.sort_custom(Callable(battle_system, "_compare_speed"))
	
	# Удаляем панель победы
	if has_node("VictoryPanel"):
		get_node("VictoryPanel").queue_free()
	
	# Сбрасываем текущий индекс хода
	battle_system.current_index = 0
	battle_system.battle_active = true
	
	# Обновляем интерфейс
	_update_interface()
	
	# Начинаем новый бой
	battle_system.emit_signal("turn_started", battle_system.combat_queue[0])

func _on_return_to_camp_pressed():
	# Все данные уже сохранены в синглтоне
	get_tree().change_scene_to_file("res://camp_system/scenes/camp.tscn")

# Обработчики действий игрока
func _on_attack_pressed():
	current_action = "attack"
	_show_targets(true)

func _on_ability_pressed():
	var popup = PopupMenu.new()
	popup.name = "AbilityMenu"
	popup.add_item("Сильный удар (3 CP)")
	popup.add_item("Лечение (8 CP)")
	popup.id_pressed.connect(_on_ability_selected)
	add_child(popup)
	popup.popup_centered()

func _on_ability_selected(id: int):
	current_action = ["strong_strike", "heal"][id]
	
	if current_action == "strong_strike":
		_show_targets(true)
	elif current_action == "heal":
		_show_targets(false)

func _on_defend_pressed():
	current_action = "defend"
	_execute_action(player)

func _on_escape_pressed():
	current_action = "escape"
	_execute_action(player)

func _on_target_selected(target: Character):
	current_target = target
	_execute_action(target)

func _execute_action(target: Character):
	action_panel.visible = false
	target_panel.visible = false
	
	var action_result = true
	var log_message = ""
	
	match current_action:
		"attack":
			var damage_dealt = player.damage
			target.take_damage(damage_dealt)
			log_message = "Вы атаковали %s и нанесли %d урона!" % [target.name, damage_dealt]
		
		"strong_strike":
			if player.cp >= 3:
				player.cp -= 3
				var damage_dealt = player.damage * 1.8 * player.special_power
				target.take_damage(damage_dealt)
				log_message = "Вы применили Сильный удар по %s и нанесли %d урона!" % [target.name, damage_dealt]
			else:
				log_message = "Недостаточно CP для Сильного удара!"
				action_result = false
		
		"heal":
			if target == player:
				if player.cp >= 8:
					player.cp -= 8
					var heal_amount = 30.0 * player.special_power
					player.hp = min(player.max_hp, player.hp + heal_amount)
					log_message = "Вы вылечились на %d HP!" % heal_amount
				else:
					log_message = "Недостаточно CP для лечения!"
					action_result = false
			else:
				log_message = "Можно лечить только себя!"
				action_result = false
		
		"defend":
			player.is_defending = true
			log_message = "Вы встали в защиту! Получаемый урон снижен на 75%"
		
		"escape":
			log_message = "Вы пытаетесь сбежать..."
			battle_system.start_escape()
	
	# Логируем действие
	if !log_message.is_empty():
		if current_action == "defend" || current_action == "escape":
			_log_action(log_message, "player")
		else:
			_log_action(log_message, "player")
	
	# Обновляем интерфейс, если действие было успешным
	if action_result:
		_update_interface()
	
	# Проверяем, не закончился ли бой после действия
	if battle_system.battle_active && action_result:
		# Если это побег, не переходим к следующему ходу
		if current_action != "escape":
			battle_system.next_turn()
	
	# Сбрасываем текущее действие
	current_action = ""
	current_target = null
