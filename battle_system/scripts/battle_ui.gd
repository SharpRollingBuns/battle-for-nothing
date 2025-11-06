class_name BattleUI
extends Control

@export var battle_system: BattleSystem
@export var hp_bar: ProgressBar
@export var cp_bar: ProgressBar
@export var action_panel: VBoxContainer
@export var target_panel: HBoxContainer
@export var enemy_info_panel: GridContainer
@export var battle_log: RichTextLabel
@export var turn_counter: Label  # Добавляем счетчик ходов

var current_action: String = ""
var current_target: Character = null
var player: Player = null


func _ready():
	var main_scene = get_tree().root.get_node("Main") # Или другое имя вашей основной сцены
	battle_system = main_scene.get_node("BattleSystem")
	
	if battle_system == null:
		# Пытаемся найти BattleSystem в другом месте
		battle_system = get_tree().current_scene.get_node("BattleSystem")
	
	if battle_system:
		battle_system.turn_started.connect(_on_turn_started)
		battle_system.battle_ended.connect(_on_battle_ended)
		
		# Находим игрока
		if battle_system.players.size() > 0:
			player = battle_system.players[0]
			_update_interface()
	else:
		push_error("BattleSystem не найден!")
	# Проверка существования всех необходимых UI элементов
	var missing_nodes = []
	if hp_bar == null: missing_nodes.append("hp_bar")
	if cp_bar == null: missing_nodes.append("cp_bar")
	if action_panel == null: missing_nodes.append("action_panel")
	if target_panel == null: missing_nodes.append("target_panel")
	if enemy_info_panel == null: missing_nodes.append("enemy_info_panel")
	if battle_log == null: missing_nodes.append("battle_log")
	if turn_counter == null: missing_nodes.append("turn_counter")
	
	if !missing_nodes.is_empty():
		var error_msg = "Не подключены следующие узлы UI: " + ", ".join(missing_nodes)
		push_error(error_msg)
		return
	
	# Скрываем панель выбора целей
	target_panel.visible = false
	
	# Подключаем сигналы системы боя
	battle_system.turn_started.connect(_on_turn_started)
	battle_system.battle_ended.connect(_on_battle_ended)
	
	# Находим игрока
	if battle_system.players.size() > 0:
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
	# Массив имен кнопок
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
		else:
			push_warning("action_panel не содержит узла %s" % button_name)


func _update_interface():
	if player == null:
		return
	
	# Обновляем прогрессбары
	hp_bar.value = player.get_hp_percent() * 100
	cp_bar.value = player.get_cp_percent() * 100
	
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
		if enemy.is_alive():
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
			if enemy.is_alive():
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
			if enemy.is_alive():
				var button = Button.new()
				button.text = enemy.name
				button.name = "Target_%d" % count
				button.pressed.connect(Callable(self, "_on_target_selected").bind(enemy))
				target_panel.add_child(button)
				count += 1
	
	# Показываем панель выбора целей
	action_panel.visible = false
	target_panel.visible = true


func _log_action(text: String):
	if battle_log:
		battle_log.add_text("\n" + text)
		battle_log.scroll_to_line(battle_log.get_line_count() - 1)


func _on_turn_started(combatant: Character):
	_update_interface()
	
	if combatant is Player:
		# Ход игрока - показываем панель действий
		action_panel.visible = true
		target_panel.visible = false
		_log_action("Ваш ход!")
	elif combatant is Enemy:
		# Ход врага - скрываем панель действий
		action_panel.visible = false
		target_panel.visible = false
		_log_action("%s ходит..." % combatant.name)
		
		# Имитируем задержку перед ходом врага
		get_tree().create_timer(1.0).timeout.connect(_handle_enemy_turn)
		_log_action("Подождите...")


func _handle_enemy_turn():
	if battle_system.battle_active:
		var current_combatant = battle_system.combat_queue[battle_system.current_index]
		if current_combatant is Enemy:
			# Выполняем действие врага
			current_combatant.act(player, battle_system.enemies)
			_update_interface()
			
			# Логируем результат
			var enemy = current_combatant as Enemy
			var damage_dealt = enemy.damage  # Это упрощенно, нужно получать реальный урон
			
			# Восстанавливаем CP за полученный урон
			var cp_gained = floor(damage_dealt * 0.1)
			player.cp = min(player.max_cp, player.cp + cp_gained)
			if cp_gained > 0:
				_log_action("Вы получили %d CP за полученный урон!" % cp_gained)
			
			# Переходим к следующему ходу
			battle_system.next_turn()


func _on_battle_ended(winner_is_player: bool):
	action_panel.visible = false
	target_panel.visible = false
	
	if winner_is_player:
		_log_action("\n[ПОБЕДА!] Все враги побеждены!")
		
		# Проверяем, был ли в бою друид
		var has_druid = false
		for enemy in battle_system.enemies:
			if enemy.enemy_type == Enemy.Type.DRUID:
				has_druid = true
				break
		
		# Если был друид - получаем опыт за каждого убитого зверя
		if has_druid:
			for enemy in battle_system.enemies:
				if enemy != player and enemy.enemy_type != Enemy.Type.DRUID and not enemy.is_alive():
					player.level_up()
					_log_action("УРОВЕНЬ ПОВЫШЕН! +1 уровень за убийство зверя в бою с друидом!")
		
		# Полное восстановление после победы
		player.hp = player.max_hp
		player.cp = player.max_cp
		_update_interface()
	else:
		_log_action("\n[ПОРАЖЕНИЕ] Вы проиграли битву...")
	
	# Показываем кнопку продолжения
	var continue_button = Button.new()
	continue_button.text = "Продолжить"
	continue_button.size_flags_horizontal = SIZE_EXPAND_FILL
	continue_button.pressed.connect(func(): get_tree().change_scene_to_file("res://main.tscn"))
	add_child(continue_button)


# Обработчики действий игрока
func _on_attack_pressed():
	current_action = "attack"
	_show_targets(true)


func _on_ability_pressed():
	var popup = PopupMenu.new()
	popup.name = "AbilityMenu"
	popup.add_item("Сильный удар (3 CP)")
	popup.add_item("Лечение (8 CP)")
	popup.add_item("Двойное действие (15 CP)")
	popup.id_pressed.connect(_on_ability_selected)
	add_child(popup)
	popup.popup_centered()


func _on_ability_selected(id: int):
	current_action = ["strong_strike", "heal", "double_action"][id]
	
	if current_action == "strong_strike":
		_show_targets(true)
	elif current_action == "heal":
		_show_targets(false)
	elif current_action == "double_action":
		_execute_action(player)


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
			
			# Восстанавливаем CP за нанесенный урон
			var cp_gained = floor(damage_dealt * 0.1)
			player.cp = min(player.max_cp, player.cp + cp_gained)
			if cp_gained > 0:
				log_message += "\nВы получили %d CP за нанесенный урон!" % cp_gained
		
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
		
		"double_action":
			if player.cp >= 15:
				player.cp -= 15
				player.extra_action_turns = 3
				log_message = "Вы получили дополнительное действие на 3 хода!"
			else:
				log_message = "Недостаточно CP для Двойного действия!"
				action_result = false
		
		"defend":
			player.is_defending = true
			log_message = "Вы встали в защиту! Получаемый урон снижен на 75%"
		
		"escape":
			log_message = "Вы пытаетесь сбежать..."
			# Побег завершится на следующем ходу
			battle_system.escape_penalty = 2
	
	# Логируем действие
	if !log_message.is_empty():
		_log_action(log_message)
	
	# Обновляем интерфейс, если действие было успешным
	if action_result:
		_update_interface()
	
	# Проверяем, не закончился ли бой после действия
	if battle_system.battle_active && action_result:
		battle_system.next_turn()
	
	# Сбрасываем текущее действие
	current_action = ""
	current_target = null
