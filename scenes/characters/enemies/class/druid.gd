class_name Druid
extends Enemy

@export var resurrect_timer: int = -1



func get_action_description(target: Character) -> String:
	var healed_target = null
	var healed_amount = 0
	
	# Ищем, кого вылечил друид
	for e in get_parent().enemies:
		if e != self and is_instance_valid(e) and e.is_alive() and e.hp < e.max_hp:
			healed_target = e
			healed_amount = 20
			break
	
	if healed_target != null:
		return "[Друид] лечит %s на %d HP!" % [healed_target.character_name, healed_amount]
	else:
		return "[Друид] не находит раненых союзников для лечения"

func act(target: Character, all_enemies: Array):
	if not is_alive():
		return
	
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
	if resurrect_timer == -1:
		resurrect_timer = 3
