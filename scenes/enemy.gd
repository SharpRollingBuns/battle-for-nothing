class_name Enemy
extends Character

enum Type {
	SKELETON,
	BOAR,
	WOLF,
	BEAR,
	DRUID
}

@export var enemy_type: Type = Type.SKELETON
@export var cooldown: int = 0
@export var enraged: bool = false
@export var resurrect_timer: int = -1
@export var original_damage: int = 0

func _ready():
	# Инициализируем базовые характеристики в зависимости от типа
	match enemy_type:
		Type.SKELETON:
			name = "Скелет"
			max_hp = 30
			max_cp = 0
			damage = 5
			speed = 8
		Type.BOAR:
			name = "Кабан"
			max_hp = 80
			max_cp = 0
			damage = 15
			speed = 10
			original_damage = damage
		Type.WOLF:
			name = "Волк"
			max_hp = 25
			max_cp = 0
			damage = 8
			speed = 18
		Type.BEAR:
			name = "Медведь"
			max_hp = 200
			max_cp = 0
			damage = 12
			speed = 6
			original_damage = damage
		Type.DRUID:
			name = "Друид"
			max_hp = 150
			max_cp = 0
			damage = 0
			speed = 12
	
	hp = max_hp
	super._ready()

func take_damage(amount: int) -> int:
	var real_damage = super.take_damage(amount)
	
	# Медведь злится при получении урона
	if enemy_type == Type.BEAR and not enraged and hp > 0:
		enraged = true
		damage = original_damage * 2
	
	return real_damage

func die():
	if enemy_type == Type.BEAR:
		enraged = false
		damage = original_damage
	super.take_damage(hp)  # Полное обнуление HP

func get_action_description(target: Character) -> String:
	var description = ""
	
	match enemy_type:
		Type.SKELETON:
			description = "[Скелет] атакует %s, нанося %d урона!" % [target.name, damage]
		
		Type.BOAR:
			if cooldown % 2 == 0:
				description = "[Кабан] бьёт копытами %s, нанося %d урона!" % [target.name, damage]
			else:
				description = "[Кабан] злится и готовится к мощной атаке..."
		
		Type.WOLF:
			description = "[Волк] нападает на %s, нанося %d урона!" % [target.name, damage]
		
		Type.BEAR:
			if enraged:
				description = "[Медведь] впадает в ярость и атакует %s, нанося %d урона!" % [target.name, damage]
				enraged = false
			else:
				description = "[Медведь] атакует %s, нанося %d урона!" % [target.name, damage]
		
		Type.DRUID:
			var healed_target = null
			var healed_amount = 0
			
			# Ищем, кого вылечил друид
			for e in get_parent().enemies:  # get_parent() - BattleSystem
				if e != self and is_instance_valid(e) and e.is_alive() and e.hp < e.max_hp:
					healed_target = e
					healed_amount = 20
					break
			
			if healed_target != null:
				description = "[Друид] лечит %s на %d HP!" % [healed_target.name, healed_amount]
			else:
				description = "[Друид] не находит раненых союзников для лечения"
	
	return description

func act(target: Character, all_enemies: Array):
	if not is_alive():
		return
	
	match enemy_type:
		Type.SKELETON, Type.WOLF:
			target.take_damage(damage)
		
		Type.BOAR:
			cooldown += 1
			if cooldown % 2 == 0:
				target.take_damage(damage)
		
		Type.BEAR:
			if enraged:
				target.take_damage(damage)
				enraged = false  # Сбрасываем ярость после атаки
			else:
				target.take_damage(damage)
		
		Type.DRUID:
			# Лечение самого раненого зверя
			var most_injured = null
			for e in all_enemies:
				if e != self and is_instance_valid(e) and e.is_alive() and (most_injured == null or e.hp < most_injured.hp):
					most_injured = e
			
			if most_injured != null:
				most_injured.hp = min(most_injured.max_hp, most_injured.hp + 20)
			
			# Воскрешение
			if resurrect_timer == 0:
				for e in all_enemies:
					if e != self and is_instance_valid(e) and not e.is_alive():
						e.hp = e.max_hp * 0.3
						resurrect_timer = -1
						break
			elif resurrect_timer > 0:
				resurrect_timer -= 1

func trigger_resurrect():
	if enemy_type == Type.DRUID and resurrect_timer == -1:
		resurrect_timer = 3

# Методы для получения базовых характеристик
func get_type_name() -> String:
	match enemy_type:
		Type.SKELETON: return "Скелет"
		Type.BOAR: return "Кабан"
		Type.WOLF: return "Волк"
		Type.BEAR: return "Медведь"
		Type.DRUID: return "Друид"
		_: return "Неизвестный"

func get_base_max_hp() -> int:
	match enemy_type:
		Type.SKELETON: return 30
		Type.BOAR: return 80
		Type.WOLF: return 25
		Type.BEAR: return 200
		Type.DRUID: return 150
		_: return 100

func get_base_damage() -> int:
	match enemy_type:
		Type.SKELETON: return 5
		Type.BOAR: return 15
		Type.WOLF: return 8
		Type.BEAR: return 12
		Type.DRUID: return 0
		_: return 10

func get_base_speed() -> int:
	match enemy_type:
		Type.SKELETON: return 8
		Type.BOAR: return 10
		Type.WOLF: return 18
		Type.BEAR: return 6
		Type.DRUID: return 12
		_: return 10
