extends Node

var player_state: PlayerState


func start_new_game(init: PlayerInit):
	player_state = PlayerState.new()
	player_state.level = init.level
	player_state.max_hp = init.max_hp
	player_state.hp = init.max_hp
	player_state.max_cp = init.max_cp
	player_state.cp = init.max_cp
	player_state.damage = init.damage
	player_state.special_power = init.special_power
	
	player_state.escape_penalty = 0
	player_state.consecutive_battles = 0


func load_game(state: PlayerState):
	player_state = state
