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
	if GameState.survival:
		var w: float = float(maxi(GameState.survival_wave - 1, 0))
		_reaction = maxf(0.06, _reaction - w * 0.012)
		_mistake = maxf(0.02, _mistake - w * 0.015)
		_aggro = minf(0.95, _aggro + w * 0.03)
		_special_bias = minf(0.72, _special_bias + w * 0.02)
		_block_bias = minf(0.8, _block_bias + w * 0.02)


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
		return
	if opp.state == Fighter.State.GRAB and dist < 100.0:
		_intent.grab = true
		_retreat()
		return
	if me.state == Fighter.State.GETUP:
		var wake := _rng.randf()
		if wake < 0.38:
			_intent.block = true
			_retreat()
		elif wake < 0.62:
			_intent.backdash = true
			_retreat()
		elif wake < 0.84:
			_intent.heavy = true
		else:
			_intent.light = true
		return
	if me.state == Fighter.State.HIT and me.special_meter >= 50.0 and _rng.randf() < 0.14:
		_intent.special = true
		_intent.block = true
		return
	if GameState.training:
		match GameState.dummy_mode:
			"stand":
				_clear()
				return
			"block":
				_clear()
				_intent.block = true
				_retreat()
				return
			"crouch":
				_clear()
				_intent.down = true
				return
			"jump":
				_clear()
				_intent.up = true
				return
			"mash":
				_clear()
				_intent.light = true
				if _rng.randf() < 0.35:
					_intent.heavy = true
				_advance()
				return
	var boll := _nearest_cotton()
	if boll != null:
		_clear()
		var opp_atk := opp.state in [Fighter.State.LIGHT, Fighter.State.HEAVY, Fighter.State.SPECIAL, Fighter.State.ULTIMATE, Fighter.State.GRAB]
		if opp_atk and dist < 140.0 and _rng.randf() < _block_bias:
			_intent.block = true
			_retreat()
			return
		_run_to(boll.global_position.x)
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
		_intent.block = true
		if _rng.randf() < 0.28:
			_advance()
		else:
			_retreat()
		if _rng.randf() < 0.45:
			_intent.down = true
		return
	if opp.state == Fighter.State.JUMP and dist < 130.0 and me.on_ground:
		_intent.heavy = true
		return
	if opp.state == Fighter.State.BLOCK and dist < 70.0 and _rng.randf() < 0.55:
		_intent.grab = true
		return
	if me.ultimate_meter >= 100.0:
		var uid: String = me.def.ultimate_id
		if uid == "vodka" and me.health < me.max_health * 0.94 and _rng.randf() < 0.7:
			_intent.ultimate = true
			return
		if uid == "vodka" and _rng.randf() < 0.28:
			_intent.ultimate = true
			return
		if uid == "grid" and dist < 420.0 and _rng.randf() < 0.5:
			_intent.ultimate = true
			return
		if uid == "dempsey" and dist < 170.0 and _rng.randf() < 0.55:
			_intent.ultimate = true
			return
		if uid == "fart" and dist < 150.0 and _rng.randf() < 0.5:
			_intent.ultimate = true
			return
		if uid == "flex" and _rng.randf() < 0.58:
			_intent.ultimate = true
			return
		if uid == "drip" and dist < 280.0 and _rng.randf() < 0.60:
			_intent.ultimate = true
			return
		if uid == "cotton" and _rng.randf() < 0.62:
			_intent.ultimate = true
			return
		if dist < 180.0 and _rng.randf() < 0.45:
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
			return
		var r := _rng.randf()
		if r < 0.30:
			_intent.block = true
			_retreat()
		elif r < 0.42:
			_retreat()
		elif r < 0.56:
			_intent.grab = true
		elif r < 0.74:
			_intent.heavy = true
			if r < 0.62:
				_intent.down = true
		elif r < 0.86:
			_intent.light = true
		else:
			_intent.block = true
			_advance()
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
	elif me.combo_hits == 1 and _rng.randf() < 0.32:
		_intent.light = true
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


func _run_to(x: float) -> void:
	var dx: float = x - me.position.x
	if dx > 8.0:
		_intent.right = true
	elif dx < -8.0:
		_intent.left = true
	if absf(dx) > 88.0:
		_intent.run = true


func _nearest_cotton() -> Node2D:
	if me == null or not me.is_inside_tree() or me.cotton_left <= 0:
		return null
	var best: Node2D = null
	var best_d := 99999.0
	for n in me.get_tree().get_nodes_in_group("cotton_pickup"):
		if n.get("owner_fighter") != me:
			continue
		var d: float = absf(n.global_position.x - me.position.x)
		if d < best_d:
			best_d = d
			best = n
	return best


func _clear() -> void:
	_intent = {
		"left": false, "right": false, "up": false, "down": false,
		"light": false, "heavy": false, "special": false, "block": false,
		"grab": false, "ultimate": false, "run": false, "qcf": false, "qcf2": false,
		"fwd": false, "back": false, "backdash": false, "dp": false,
	}
