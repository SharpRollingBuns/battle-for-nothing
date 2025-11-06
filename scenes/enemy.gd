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
	# Устанавливаем параметры врага в зависимости от типа
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
	
	# Инициализируем текущие значения
	hp = max_hp
	super._ready()


func take_damage(amount: int) -> int:
	var real_damage = super.take_damage(amount)
	
	# Медведь злится при получении урона
	if enemy_type == Type.BEAR and not enraged and hp > 0:
		enraged = true
		damage = original_damage * 2
	
	return real_damage


func act(hunter: Player, all_enemies: Array[Enemy]):
	if not is_alive():
		return
	
	match enemy_type:
		Type.SKELETON, Type.WOLF:
			hunter.take_damage(damage)
		
		Type.BOAR:
			cooldown += 1
			if cooldown % 2 == 0:
				hunter.take_damage(damage)
		
		Type.BEAR:
			if enraged:
				hunter.take_damage(damage)
				enraged = false  # Сбрасываем ярость после атаки
			else:
				hunter.take_damage(damage)
		
		Type.DRUID:
			# Лечение самого раненого зверя
			var most_injured = null
			for e in all_enemies:
				if e != self and e.is_alive() and (most_injured == null or e.hp < most_injured.hp):
					most_injured = e
			
			if most_injured != null:
				most_injured.hp = min(most_injured.max_hp, most_injured.hp + 20)
			
			# Воскрешение
			if resurrect_timer == 0:
				for e in all_enemies:
					if e != self and not e.is_alive():
						e.hp = e.max_hp * 0.3
						resurrect_timer = -1
						break
			elif resurrect_timer > 0:
				resurrect_timer -= 1


func trigger_resurrect():
	if enemy_type == Type.DRUID and resurrect_timer == -1:
		resurrect_timer = 3
