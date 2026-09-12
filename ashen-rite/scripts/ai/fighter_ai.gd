class_name FighterAI
extends Node
## Reacts to observable fighter state with delayed decisions. Does not read player input.

var me: Fighter
var _intent: Dictionary = {}
var _think_cd: float = 0.0
var _reaction: float = 0.28
var _mistake: float = 0.18
var _block_bias: float = 0.35
var _special_bias: float = 0.25
var _aggro: float = 0.55
var _rng := RandomNumberGenerator.new()


func setup(fighter: Fighter) -> void:
	me = fighter
	_rng.randomize()
	_apply_difficulty()
	_clear()


func _apply_difficulty() -> void:
	match GameState.difficulty:
		GameState.Difficulty.EASY:
			_reaction = 0.48
			_mistake = 0.38
			_block_bias = 0.12
			_special_bias = 0.08
			_aggro = 0.35
		GameState.Difficulty.NORMAL:
			_reaction = 0.28
			_mistake = 0.18
			_block_bias = 0.32
			_special_bias = 0.22
			_aggro = 0.55
		GameState.Difficulty.HARD:
			_reaction = 0.16
			_mistake = 0.08
			_block_bias = 0.55
			_special_bias = 0.4
			_aggro = 0.7
		GameState.Difficulty.EXPERT:
			_reaction = 0.09
			_mistake = 0.03
			_block_bias = 0.68
			_special_bias = 0.5
			_aggro = 0.82
	match me.def.ai_profile:
		"rushdown":
			_aggro += 0.12
		"turtle":
			_block_bias += 0.12
			_aggro -= 0.1
		"mixup":
			_mistake *= 0.7


func poll() -> Dictionary:
	return _intent.duplicate()


func _process(delta: float) -> void:
	if me == null or me.opponent == null or me.round_over:
		_clear()
		return
	var dist := me.distance_to_opponent()
	var opp := me.opponent
	if me.state == Fighter.State.HIT and not me.on_ground and me.hitstun <= 0.16:
		_intent.up = true
		_intent.light = true
		return
	if opp.state == Fighter.State.GRAB and dist < 100.0:
		_intent.grab = true
		_retreat()
		return
	if me.state == Fighter.State.GETUP:
		_intent.light = true
		if _rng.randf() < 0.35:
			_intent.heavy = true
		return
	if me.state == Fighter.State.BLOCK and me.hitstun > 0.0 and me.special_meter >= 25.0 and _rng.randf() < 0.22:
		_intent.special = true
		return
	_think_cd -= delta
	if _think_cd > 0.0:
		return
	_think_cd = _reaction + _rng.randf_range(0.0, 0.08)
	_clear()
	if _rng.randf() < _mistake:
		_wander()
		return
	dist = me.distance_to_opponent()
	var opp_attacking := opp.state in [Fighter.State.LIGHT, Fighter.State.HEAVY, Fighter.State.SPECIAL, Fighter.State.ULTIMATE, Fighter.State.GRAB]
	if opp.state == Fighter.State.GRAB and dist < 90.0:
		_intent.grab = true
		_retreat()
		return
	if opp_attacking and dist < 150.0 and _rng.randf() < _block_bias:
		_retreat()
		_intent.block = true
		if _rng.randf() < 0.45:
			_intent.down = true
		return
	if opp.state == Fighter.State.JUMP and dist < 130.0 and me.on_ground:
		_intent.heavy = true
		return
	if opp.state == Fighter.State.BLOCK and dist < 70.0 and _rng.randf() < 0.55:
		_intent.grab = true
		return
	if me.ultimate_meter >= 100.0 and dist < 180.0 and _rng.randf() < 0.45:
		_intent.ultimate = true
		return
	if me.special_meter >= 50.0 and dist < 260.0 and _rng.randf() < _special_bias:
		_intent.special = true
		_advance()
		return
	var prefer_close := _aggro > 0.6
	if dist > 170.0:
		_advance()
		if dist > 240.0:
			_intent.run = true
		if dist > 280.0 and me.on_ground and _rng.randf() < 0.12:
			_intent.up = true
		return
	if dist < 48.0 and not prefer_close:
		_retreat()
		return
	if dist < 90.0:
		if opp.state == Fighter.State.HIT and me.combo_hits > 0:
			_combo()
		elif _rng.randf() < 0.22:
			_intent.down = true
			_intent.heavy = true
		elif _rng.randf() < 0.55:
			_intent.light = true
		elif _rng.randf() < 0.5:
			_intent.heavy = true
		else:
			_intent.grab = true
		return
	if _rng.randf() < 0.2:
		_intent.down = true
	else:
		_advance()


func _combo() -> void:
	if me.ultimate_meter >= 100.0 and me.combo_hits >= 2:
		_intent.ultimate = true
	elif me.combo_hits >= 2 and me.special_meter >= 50.0:
		_intent.special = true
	elif me.combo_hits >= 1:
		_intent.heavy = true
	else:
		_intent.light = true


func _advance() -> void:
	if me.opponent.position.x >= me.position.x:
		_intent.right = true
	else:
		_intent.left = true


func _retreat() -> void:
	if me.opponent.position.x >= me.position.x:
		_intent.left = true
	else:
		_intent.right = true


func _wander() -> void:
	if _rng.randf() < 0.5:
		_intent.left = true
	else:
		_intent.right = true
	if _rng.randf() < 0.15:
		_intent.light = true


func _clear() -> void:
	_intent = {
		"left": false, "right": false, "up": false, "down": false,
		"light": false, "heavy": false, "special": false, "block": false,
		"grab": false, "ultimate": false, "run": false, "qcf": false, "qcf2": false,
		"fwd": false, "back": false, "backdash": false,
	}
