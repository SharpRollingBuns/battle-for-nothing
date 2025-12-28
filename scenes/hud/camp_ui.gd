class_name CampUI
extends Control

signal rest_button_pressed
signal hunt_button_pressed


func _on_rest_button_pressed() -> void:
	rest_button_pressed.emit()


func _on_hunt_button_pressed() -> void:
	hunt_button_pressed.emit()


func update_player_info(player_state: PlayerState):
	update_level(player_state.level)
	update_hp(player_state.hp, player_state.max_hp)
	update_cp(player_state.cp, player_state.max_cp)


func update_hp(hp: int, max_hp: int):
	%HPLabel.text = "%d / %d" % [hp, max_hp]
	%HPBar.max_value = max_hp
	%HPBar.value = hp


func update_cp(cp: int, max_cp: int):
	%CPLabel.text = "%d / %d" % [cp, max_cp]
	%CPBar.max_value = max_cp
	%CPBar.value = cp


func update_level(new_lvl: int):
	%LevelLabel.text = "Уровень: %d" % [new_lvl]


func write_log(message: String):
	%LogLabel.text = message
