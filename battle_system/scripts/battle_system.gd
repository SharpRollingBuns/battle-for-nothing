class_name BattleSystem
extends Node

signal turn_started(combatant)
signal battle_ended(winner_is_player)

var players: Array[Player] = []
var enemies: Array[Enemy] = []
var combat_queue: Array = []
var current_index: int = 0
var battle_active: bool = false


func _ready():
	# Инициализируем бой при старте
	initialize_battle()


func initialize_battle():
	# Очищаем предыдущие данные
	players.clear()
	enemies.clear()
	combat_queue.clear()
	
	# Сканируем только прямых потомков BattleSystem
	for child in get_children():
		if child is Player:
			players.append(child)
			# Инициализируем характеристики игрока
			child.hp = child.max_hp
			child.cp = child.max_cp
		elif child is Enemy:
			enemies.append(child)
			# Инициализируем характеристики врага
			child.hp = child.max_hp
			child.cp = child.max_cp
	
	# Проверяем наличие хотя бы одного игрока и врага
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
	
	# Отправляем сигнал о начале первого хода
	emit_signal("turn_started", combat_queue[current_index])
	if combat_queue.size() > 0:
		emit_signal("turn_started", combat_queue[0])
	else:
		print("Ошибка: Очередь боя пуста!")


func _compare_speed(a: Character, b: Character) -> bool:
	# Сортировка по убыванию скорости (кто быстрее - ходит первым)
	return a.speed > b.speed


func next_turn():
	if not battle_active:
		return
	
	# Переходим к следующему участнику
	current_index = (current_index + 1) % combat_queue.size()
	
	# Проверяем, жив ли текущий участник
	while not combat_queue[current_index].is_alive():
		current_index = (current_index + 1) % combat_queue.size()
		
		# Проверка окончания боя
		if _check_battle_end():
			return
	
	
	# Вызываем сигнал начала хода
	emit_signal("turn_started", combat_queue[current_index])


func _check_battle_end() -> bool:
	# Проверяем, остались ли живые игроки
	var players_alive = false
	for player in players:
		if player.is_alive():
			players_alive = true
			break
	
	# Проверяем, остались ли живые враги
	var enemies_alive = false
	for enemy in enemies:
		if enemy.is_alive():
			enemies_alive = true
			break
	
	# Если нет живых игроков или врагов - бой окончен
	if not players_alive or not enemies_alive:
		battle_active = false
		emit_signal("battle_ended", players_alive)
		return true
	
	return false
