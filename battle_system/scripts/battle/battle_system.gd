class_name BattleSystem
extends Node

signal turn_started(combatant)
signal battle_ended(winner_is_player)

var players: Array[Player] = []
var enemies: Array[Enemy] = []
var combat_queue: Array = []
var current_index: int = 0
var battle_active: bool = false
var escape_penalty: int = 0
var escape_active: bool = false
var escape_turns: int = 0
var turn_order_indicators: Array[Node] = []

# Сопоставление типов врагов с их именами
var enemy_type_names = ["Скелет", "Кабан", "Волк", "Медведь", "Друид"]

func _ready():
	initialize_battle()

func initialize_battle():
	players.clear()
	enemies.clear()
	combat_queue.clear()
	turn_order_indicators.clear()
	
	# Сканируем только прямых потомков BattleSystem
	for child in get_children():
		if child is Player:
			players.append(child)
			child.hp = child.max_hp
			child.cp = child.max_cp
		elif child is Enemy:
			enemies.append(child)
			child.hp = child.max_hp
	
	if players.is_empty() or enemies.is_empty():
		print("Ошибка: Недостаточно участников боя (игроков или врагов)")
		return
	
	# Формируем очередь боя
	for player in players:
		combat_queue.append(player)
	for enemy in enemies:
		combat_queue.append(enemy)
	
	# Сортируем по скорости (от высокой к низкой)
	combat_queue.sort_custom(Callable(self, "_compare_speed"))
	
	# Стартуем бой
	battle_active = true
	current_index = 0
	
	# Создаем индикаторы очереди ходов
	_create_turn_order_indicators()
	
	# Отправляем сигнал о начале первого хода
	if combat_queue.size() > 0:
		emit_signal("turn_started", combat_queue[current_index])

func _compare_speed(a: Character, b: Character) -> bool:
	return a.speed > b.speed

func _create_order_indicator(combatant: Character, position: int) -> Node2D:
	if combatant == null:
		print("Предупреждение: combatant равен null!")
		return Node2D.new()
	
	var indicator = Node2D.new()
	# Устанавливаем имя индикатора, чтобы оно не конфликтовало с именем узла
	indicator.name = "TurnIndicator_%s" % (combatant.character_name if combatant.character_name != "" else "unknown")
	
	# Создаем визуальный элемент индикатора
	var color_rect = ColorRect.new()
	color_rect.size = Vector2(30, 30)
	
	# Определяем цвет индикатора
	if combatant is Player:
		color_rect.color = Color(0.2, 0.7, 0.9)  # Голубой для игрока
	else:
		# Цвет для врагов в зависимости от типа
		if combatant is Enemy:
			color_rect.color = combatant.get_enemy_color()
		else:
			color_rect.color = Color(0.7, 0.7, 0.7)  # Серый для других типов
	
	# Позиционируем индикатор над персонажем
	color_rect.position = Vector2(0, -40)
	indicator.add_child(color_rect)
	
	# Создаем метку с номером хода
	var label = Label.new()
	label.text = str(position + 1)
	label.add_theme_font_size_override("font_size", 18)
	label.position = Vector2(-5, -5)
	color_rect.add_child(label)
	
	# Если это текущий ход, выделяем индикатор
	if position == current_index:
		color_rect.modulate = Color(1, 1, 0.5, 1)
	else:
		color_rect.modulate = Color.WHITE
	
	# Позиционируем индикатор относительно персонажа
	if is_instance_valid(combatant):
		indicator.position = combatant.global_position
	else:
		indicator.position = Vector2(0, 0)
	
	return indicator

func next_turn():
	if !battle_active:
		return
	
	# Переходим к следующему участнику
	current_index = (current_index + 1) % combat_queue.size()
	
	# Пропускаем мертвых и удаленных объектов
	var valid_index_found = false
	for i in range(combat_queue.size()):
		if current_index >= combat_queue.size():
			current_index = 0
		
		if current_index >= combat_queue.size():
			break
		
		var combatant = combat_queue[current_index]
		if is_instance_valid(combatant) and combatant.is_alive():
			valid_index_found = true
			break
		
		# Удаляем недействительные объекты из очереди
		combat_queue.remove_at(current_index)
	
	# Проверка окончания боя
	if _check_battle_end():
		return
	
	# Если не нашли валидного участника, завершаем бой
	if not valid_index_found:
		end_battle(false)
		return
	
	# Обновляем индикаторы очереди
	_update_turn_indicators()
	
	# Отправляем сигнал о начале нового хода
	if combat_queue.size() > 0:
		emit_signal("turn_started", combat_queue[current_index])

func _update_turn_indicators():
	for i in range(turn_order_indicators.size()):
		var indicator = turn_order_indicators[i]
		if is_instance_valid(indicator) and indicator.get_child_count() > 0:
			var color_rect = indicator.get_child(0)
			if i == current_index:
				color_rect.modulate = Color(1.0, 1.0, 0.5, 1.0)  # Выделяем текущий ход
			else:
				color_rect.modulate = Color.WHITE

func _check_battle_end() -> bool:
	var players_alive = false
	for player in players:
		if is_instance_valid(player) and player.is_alive():
			players_alive = true
			break
	
	var enemies_alive = false
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			enemies_alive = true
			break
	
	if !players_alive or !enemies_alive:
		battle_active = false
		emit_signal("battle_ended", players_alive)
		return true
	
	return false

func start_escape():
	escape_active = true
	escape_turns = 1

func _check_escape():
	if escape_active:
		escape_turns -= 1
		if escape_turns <= 0:
			end_battle(true)  # Побег успешен
			return true
	return false

func end_battle(winner_is_player: bool = false):
	battle_active = false
	emit_signal("battle_ended", winner_is_player)

func generate_new_enemy_party(player_level: int) -> Array:
	var new_enemies = []
	
	# Определяем количество врагов (1-5)
	var enemy_count = min(5, 1 + randi() % max(2, int(floor(player_level / 10)) + 1))
	
	# Получаем фиксированные позиции для врагов
	var positions = _get_fixed_enemy_positions(enemy_count)
	
	# Генерируем врагов в зависимости от уровня
	for i in range(enemy_count):
		var enemy_type = _get_enemy_type_by_level(player_level)
		var enemy = Enemy.new()
		enemy.enemy_type = enemy_type
		enemy.character_name = enemy.get_type_name()
		
		# Устанавливаем характеристики
		enemy.max_hp = enemy.get_base_max_hp()
		enemy.hp = enemy.max_hp
		enemy.damage = enemy.get_base_damage()
		enemy.speed = enemy.get_base_speed()
		
		# Устанавливаем позицию
		if i < positions.size():
			enemy.global_position = positions[i]
		
		new_enemies.append(enemy)
	
	return new_enemies

func _get_fixed_enemy_positions(enemy_count: int) -> Array:
	var positions = []
	var screen_center = Vector2(1280, 720) / 2.0
	
	# Фиксированные позиции для врагов справа от центра экрана
	match enemy_count:
		1:
			positions.append(screen_center + Vector2(400, 0))
		2:
			positions.append(screen_center + Vector2(400, -100))
			positions.append(screen_center + Vector2(400, 100))
		3:
			positions.append(screen_center + Vector2(400, -150))
			positions.append(screen_center + Vector2(400, 0))
			positions.append(screen_center + Vector2(400, 150))
		4:
			positions.append(screen_center + Vector2(350, -150))
			positions.append(screen_center + Vector2(450, -150))
			positions.append(screen_center + Vector2(350, 150))
			positions.append(screen_center + Vector2(450, 150))
		5:
			positions.append(screen_center + Vector2(350, -200))
			positions.append(screen_center + Vector2(450, -200))
			positions.append(screen_center + Vector2(400, 0))
			positions.append(screen_center + Vector2(350, 200))
			positions.append(screen_center + Vector2(450, 200))
	
	return positions

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
		return 0  # Enemy.Type.SKELETON
	elif r < skeleton_prob + wolf_prob:
		return 1  # Enemy.Type.WOLF
	elif r < skeleton_prob + wolf_prob + boar_prob:
		return 2  # Enemy.Type.BOAR
	elif r < skeleton_prob + wolf_prob + boar_prob + bear_prob:
		return 3  # Enemy.Type.BEAR
	else:
		return 4  # Enemy.Type.DRUID


func _create_turn_order_indicators():
	# Очищаем старые индикаторы
	for indicator in turn_order_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	turn_order_indicators.clear()
	
	# Создаем индикаторы для каждого участника
	for i in range(combat_queue.size()):
		var combatant = combat_queue[i]
		if is_instance_valid(combatant):
			var indicator = _create_order_indicator(combatant, i)
			turn_order_indicators.append(indicator)
			# Добавляем индикатор в сцену
			if get_tree() != null && get_tree().current_scene != null:
				get_tree().current_scene.add_child(indicator)
