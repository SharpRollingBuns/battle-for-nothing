class_name Player
extends Character


enum PlayerState {
	IDLE,
	ON_GUARD,
	ATTACKING,
	DEATH,
}

@export var special_power: float = 1.0
@export var cp_gain: float = 0.1
@export var level: int = 1
@export var xp: int = 0

var current_state = PlayerState.IDLE


func _ready():
	super._ready()
	assert(GameSession.player_state != null)
	apply_state(GameSession.player_state)


func apply_state(state: PlayerState):
	level = state.level
	hp = state.hp
	max_hp = state.max_hp
	cp = state.cp
	max_cp = state.max_cp
	damage = state.damage
	special_power = state.special_power


func sync_state(state: PlayerState):
	state.level = level
	state.hp = hp
	state.max_hp = max_hp
	state.cp = cp
	state.max_cp = max_cp
	state.damage = damage
	state.special_power = special_power


func take_damage(amount: int) -> int:
	if current_state == PlayerState.ON_GUARD:
		amount = int(amount / 4.0)
	super.take_damage(amount)
	
	cp = min(max_cp, cp + int(amount * cp_gain))
	
	return amount


func deal_damage(target: Character, amount: int):
	super.deal_damage(target, amount)
	cp = min(max_cp, cp + int(amount * cp_gain))


func level_up():
	level += 1
	max_hp = floor(10 * pow(level, 1.7) + level)
	max_cp = floor(2 * pow(level, 1.3) + level)
	damage = floor(pow(level, 1.6) + level)
	special_power = pow(level, 2)
	hp = max_hp
	cp = max_cp
