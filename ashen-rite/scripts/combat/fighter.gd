class_name Fighter
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal meters_changed(special: float, ultimate: float)
signal defeated(fighter: Fighter)
signal hit_landed(fighter: Fighter, attack: Dictionary, counter: bool)
signal combo_changed(count: int)

enum State { IDLE, WALK, RUN, BACKDASH, PREJUMP, JUMP, LAND, CROUCH, LIGHT, HEAVY, SPECIAL, ULTIMATE, BLOCK, GRAB, HIT, KNOCKDOWN, GETUP, VICTORY, DEFEAT }

const GRAVITY := 2800.0
const MAX_SPECIAL := 100.0
const MAX_ULTIMATE := 100.0
const WALK_BACK := 0.72
const RUN_MUL := 1.85
const AIR_CTRL := 0.08

var fighter_id: int = 0
var def: CharacterDef
var is_cpu: bool = false
var opponent: Fighter
var input_map: Dictionary = {}

var state: State = State.IDLE
var facing: int = 1
var health: float = 1000.0
var max_health: float = 1000.0
var special_meter: float = 0.0
var ultimate_meter: float = 0.0
var hitstun: float = 0.0
var attack_timer: float = 0.0
var attack_duration: float = 0.0
var attack_active_from: float = 0.0
var attack_active_until: float = 0.0
var recovery_lock: bool = false
var on_ground: bool = false
var freeze_frames: float = 0.0
var invuln: float = 0.0
var combo_hits: int = 0
var combo_decay: float = 0.0
var current_attack: Dictionary = {}
var round_over: bool = false
var can_act: bool = true
var last_attack_was_hit: bool = false
var chain_window: float = 0.0
var last_chain: Array[String] = []
var air_done: bool = false
var _buf = preload("res://scripts/combat/motion_buffer.gd").new()
var _land_t: float = 0.0
var _dash_t: float = 0.0
var _jump_x: float = 0.0
var _was_air: bool = false
var guarding: bool = false
var crouch_guarding: bool = false

var visual: FighterVisual
var hurtbox: Area2D
var hitbox: Hitbox
var _ai: FighterAI
var _ground_y := 0.0


func setup(id: int, character: CharacterDef, cpu: bool, start_pos: Vector2) -> void:
	fighter_id = id
	def = character
	is_cpu = cpu
	position = start_pos
	max_health = def.health
	health = max_health
	motion_mode = MOTION_MODE_GROUNDED
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 12.0
	floor_max_angle = 0.8

	var body := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = 18.0 * def.width_scale
	cap.height = 92.0 * def.height_scale
	body.shape = cap
	body.position = Vector2(0, -48 * def.height_scale)
	add_child(body)

	hurtbox = Area2D.new()
	hurtbox.collision_layer = 8
	hurtbox.collision_mask = 0
	hurtbox.monitorable = true
	hurtbox.monitoring = false
	hurtbox.set_meta("fighter_id", fighter_id)
	var hs := CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = Vector2(36 * def.width_scale, 96 * def.height_scale)
	hs.shape = hrect
	hs.position = Vector2(0, -50 * def.height_scale)
	hurtbox.add_child(hs)
	add_child(hurtbox)

	hitbox = Hitbox.new()
	hitbox.owner_fighter = self
	hitbox.landed.connect(_on_hitbox_landed)
	add_child(hitbox)

	visual = FighterVisual.new()
	add_child(visual)
	visual.build(def)

	input_map = ControlMap.map_for(id)
	if cpu:
		_ai = FighterAI.new()
		_ai.setup(self)
		add_child(_ai)

	health_changed.emit(health, max_health)
	meters_changed.emit(special_meter, ultimate_meter)


func reset_round(start_pos: Vector2) -> void:
	position = start_pos
	velocity = Vector2.ZERO
	health = max_health
	state = State.IDLE
	hitstun = 0.0
	attack_timer = 0.0
	round_over = false
	can_act = false
	invuln = 0.4
	combo_hits = 0
	last_chain.clear()
	hitbox.disarm()
	air_done = false
	_buf.reset()
	_dash_t = 0.0
	_land_t = 0.0
	rotation = 0
	visual.rotation = 0
	visual.set_pose_name("idle")
	health_changed.emit(health, max_health)


func lock_out() -> void:
	round_over = true
	can_act = false
	hitbox.disarm()


func celebrate(win: bool) -> void:
	lock_out()
	state = State.VICTORY if win else State.DEFEAT
	visual.set_pose_name("victory" if win else "defeat")


func _physics_process(delta: float) -> void:
	if freeze_frames > 0.0:
		freeze_frames -= delta
		return
	invuln = max(0.0, invuln - delta)
	combo_decay = max(0.0, combo_decay - delta)
	chain_window = max(0.0, chain_window - delta)
	if combo_decay <= 0.0 and combo_hits != 0:
		combo_hits = 0
		last_chain.clear()
		combo_changed.emit(0)

	on_ground = is_on_floor()
	if not on_ground:
		velocity.y += GRAVITY * delta
	elif _was_air:
		_on_landed()
	var cmd := _gather_command()
	_face_opponent()
	if not round_over:
		_think(cmd, delta)
	_integrate(delta)
	_sync_visual()
	move_and_slide()
	on_ground = is_on_floor()
	_was_air = not on_ground
	_separate_from_opponent()
	_keep_in_bounds()


func _gather_command() -> Dictionary:
	var cmd := {
		"left": false, "right": false, "up": false, "down": false,
		"light": false, "heavy": false, "special": false, "block": false,
		"grab": false, "ultimate": false,
		"fwd": false, "back": false, "run": false, "backdash": false,
		"qcf": false, "qcf2": false,
	}
	if round_over or not can_act:
		return cmd
	if is_cpu and _ai:
		var a: Dictionary = _ai.poll()
		for k in cmd.keys():
			if a.has(k):
				cmd[k] = a[k]
		cmd.fwd = (facing > 0 and cmd.right) or (facing < 0 and cmd.left)
		cmd.back = (facing > 0 and cmd.left) or (facing < 0 and cmd.right)
		return cmd
	for k in ["left", "right", "up", "down", "light", "heavy", "special", "block", "grab", "ultimate"]:
		if input_map.has(k):
			if k in ["light", "heavy", "special", "grab", "ultimate"]:
				cmd[k] = Input.is_action_just_pressed(input_map[k])
			else:
				cmd[k] = Input.is_action_pressed(input_map[k])
	var mot: Dictionary = _buf.push(cmd.left, cmd.right, cmd.up, cmd.down, facing, get_physics_process_delta_time())
	cmd.fwd = mot.fwd
	cmd.back = mot.back
	cmd.run = mot.run
	cmd.backdash = mot.backdash
	cmd.qcf = mot.qcf
	cmd.qcf2 = mot.qcf2
	return cmd


func _think(cmd: Dictionary, delta: float) -> void:
	guarding = on_ground and (cmd.back or cmd.block) and not _busy_attack()
	crouch_guarding = guarding and (cmd.down or state == State.CROUCH)

	if state == State.BLOCK and hitstun > 0.0:
		hitstun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 1800.0 * delta)
		return
	if state == State.HIT:
		hitstun -= delta
		if on_ground:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if hitstun <= 0.0:
			state = State.IDLE if on_ground else State.JUMP
			air_done = not on_ground
		return
	if state == State.KNOCKDOWN:
		hitstun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
		if hitstun <= 0.0 and on_ground:
			state = State.GETUP
			_land_t = 0.18
			invuln = 0.22
		return
	if state == State.GETUP or state == State.LAND:
		_land_t -= delta
		velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
		if _land_t <= 0.0:
			state = State.CROUCH if cmd.down else State.IDLE
		return
	if state == State.PREJUMP:
		_land_t -= delta
		velocity.x = 0.0
		if _land_t <= 0.0:
			_leave_ground()
		return
	if state == State.BACKDASH:
		_dash_t -= delta
		if _dash_t <= 0.0:
			state = State.IDLE
		return
	if _busy_attack():
		attack_timer += delta
		visual.attack_u = clamp(attack_timer / max(attack_duration, 0.01), 0.0, 1.0)
		if attack_timer >= attack_active_from and attack_timer <= attack_active_until:
			if not hitbox.active:
				hitbox.arm(current_attack)
		elif hitbox.active and attack_timer > attack_active_until:
			hitbox.disarm()
		if attack_timer >= attack_duration:
			hitbox.disarm()
			chain_window = 0.16
			if not on_ground:
				state = State.JUMP
				air_done = true
			else:
				state = State.CROUCH if cmd.down else State.IDLE
		elif last_attack_was_hit and attack_timer > attack_active_until:
			if not _try_jump_cancel(cmd):
				_try_chain(cmd)
		return

	var want_super: bool = cmd.ultimate or (cmd.qcf2 and (cmd.light or cmd.heavy or cmd.special))
	if want_super and ultimate_meter >= MAX_ULTIMATE:
		_buf.consume_motion()
		_start_attack("ultimate")
		if opponent:
			opponent.freeze_frames = max(opponent.freeze_frames, 0.28)
		freeze_frames = max(freeze_frames, 0.12)
		return
	var want_special: bool = (cmd.special and special_meter >= 50.0) or (cmd.qcf and (cmd.light or cmd.heavy or cmd.special) and special_meter >= 50.0)
	if want_special:
		_buf.consume_motion()
		_start_attack("special")
		return

	if cmd.grab and on_ground:
		_start_attack("grab")
		return

	if cmd.heavy:
		var hk := _normal_kind("heavy", cmd)
		if not (hk.begins_with("j") and air_done):
			_start_attack(hk)
			return
	if cmd.light:
		var lk := _normal_kind("light", cmd)
		if not (lk.begins_with("j") and air_done):
			_start_attack(lk)
			return

	if cmd.up and on_ground:
		_begin_jump(cmd)
		return

	if cmd.backdash and on_ground:
		state = State.BACKDASH
		_dash_t = 0.22
		invuln = 0.12
		velocity.x = float(facing) * -420.0
		return

	if not on_ground:
		if state != State.JUMP:
			state = State.JUMP
		velocity.x = move_toward(velocity.x, _jump_x, def.speed * AIR_CTRL)
		return

	if cmd.down:
		state = State.CROUCH
		velocity.x = move_toward(velocity.x, 0.0, def.speed * 14.0 * delta)
		return

	if cmd.block and not cmd.fwd:
		state = State.BLOCK
		velocity.x = move_toward(velocity.x, 0.0, def.speed * 14.0 * delta)
		return

	if cmd.run or (state == State.RUN and cmd.fwd):
		state = State.RUN
		velocity.x = float(facing) * def.speed * RUN_MUL
		return

	if cmd.fwd:
		state = State.WALK
		velocity.x = float(facing) * def.speed
		return
	if cmd.back:
		state = State.WALK
		velocity.x = float(facing) * -def.speed * WALK_BACK
		return

	state = State.IDLE
	velocity.x = move_toward(velocity.x, 0.0, def.speed * 16.0 * delta)


func _normal_kind(base: String, cmd: Dictionary) -> String:
	if not on_ground:
		return "j" + base
	if cmd.down:
		return "c" + base
	return base


func _begin_jump(cmd: Dictionary) -> void:
	var jx: float = 0.0
	if cmd.fwd:
		jx = float(facing) * def.speed * 1.05
	elif cmd.back:
		jx = float(facing) * -def.speed * 0.82
	_jump_x = jx
	state = State.PREJUMP
	_land_t = 0.05
	velocity.x = 0.0
	AudioDirector.play("whoosh", 1.25, 0.4)


func _leave_ground() -> void:
	velocity.y = -def.jump * 1.9
	velocity.x = _jump_x
	state = State.JUMP
	on_ground = false
	air_done = false


func _on_landed() -> void:
	air_done = false
	velocity.x *= 0.45
	if _busy_attack() and str(current_attack.get("kind", "")).begins_with("j"):
		hitbox.disarm()
		state = State.LAND
		_land_t = 0.12
		attack_timer = attack_duration
	elif state == State.JUMP or state == State.PREJUMP:
		state = State.LAND
		_land_t = 0.09


func _try_jump_cancel(cmd: Dictionary) -> bool:
	if not on_ground or not cmd.up:
		return false
	var k: String = str(current_attack.get("kind", ""))
	if k not in ["light", "clight", "heavy", "cheavy"]:
		return false
	hitbox.disarm()
	_begin_jump(cmd)
	return true


func _try_chain(cmd: Dictionary) -> void:
	var next := ""
	if cmd.light:
		next = _normal_kind("light", cmd)
	elif cmd.heavy:
		next = _normal_kind("heavy", cmd)
	elif (cmd.special or cmd.qcf) and special_meter >= 50.0:
		next = "special"
	if next.is_empty():
		return
	var k: String = str(current_attack.get("kind", ""))
	var allowed := false
	if k in ["light", "clight", "jlight"]:
		allowed = next in ["light", "clight", "heavy", "cheavy", "special"]
	elif k in ["heavy", "cheavy", "jheavy"]:
		allowed = next in ["special"]
	if allowed:
		_start_attack(next)


func _start_attack(kind: String) -> void:
	var atk := CombatRules.make_attack(kind, def)
	current_attack = atk
	last_attack_was_hit = false
	attack_timer = 0.0
	attack_duration = atk.duration
	attack_active_from = atk.startup
	attack_active_until = atk.startup + atk.active
	hitbox.disarm()
	hitbox.configure(atk.size, Vector2(atk.reach * facing, atk.y))
	match kind:
		"light", "clight", "jlight":
			state = State.LIGHT
			AudioDirector.play("whoosh", 1.35, 0.5)
		"heavy", "cheavy", "jheavy":
			state = State.HEAVY
			AudioDirector.play("whoosh", 0.85, 0.6)
		"special":
			state = State.SPECIAL
			special_meter = max(0.0, special_meter - 50.0)
			AudioDirector.play("special")
			if def.special_id == "dash":
				velocity.x = facing * 680.0
				velocity.y = -80.0
			elif def.special_id == "slam":
				velocity.y = -240.0
			_spawn_projectile_if_any()
		"ultimate":
			state = State.ULTIMATE
			ultimate_meter = 0.0
			AudioDirector.play("ultimate")
			_spawn_projectile_if_any()
		"grab":
			state = State.GRAB
			AudioDirector.play("grab")
	meters_changed.emit(special_meter, ultimate_meter)
	last_chain.append(kind)
	if last_chain.size() > 6:
		last_chain.pop_front()
	var step: float = float(current_attack.get("step", 0.0))
	if on_ground and step != 0.0:
		velocity.x = float(facing) * step


func _spawn_projectile_if_any() -> void:
	var kind: String = current_attack.get("projectile", "")
	if kind.is_empty():
		return
	var p := Projectile.new()
	p.setup(self, kind, def.accent)
	p.position = global_position + Vector2(40 * facing, -70)
	p.velocity = Vector2(current_attack.get("proj_speed", 520.0) * facing, 0)
	get_parent().add_child(p)


func _busy_attack() -> bool:
	return state in [State.LIGHT, State.HEAVY, State.SPECIAL, State.ULTIMATE, State.GRAB]


func _on_hitbox_landed(area: Area2D, attack: Dictionary) -> void:
	var other := area.get_parent()
	while other and not (other is Fighter):
		other = other.get_parent()
	if other == null or other == self:
		return
	(other as Fighter).receive_hit(self, attack)


func receive_hit(attacker: Fighter, attack: Dictionary) -> void:
	if invuln > 0.0 or state == State.DEFEAT:
		return
	var grabbing: bool = attack.get("kind", "") == "grab"
	var gkind: String = str(attack.get("guard", "mid"))
	var can_guard: bool = guarding and on_ground and not grabbing and state != State.PREJUMP
	if can_guard and gkind == "low" and not crouch_guarding:
		can_guard = false
	if can_guard and gkind == "high" and crouch_guarding:
		can_guard = false
	var blocked := can_guard or ((state == State.BLOCK or state == State.BACKDASH) and not grabbing)
	var dmg: float = float(attack.damage) * attacker.def.attack / max(def.defense, 0.2)
	if blocked:
		dmg *= 0.08
		AudioDirector.play("block", 1.0, 0.8)
		special_meter = min(MAX_SPECIAL, special_meter + 3.0)
		attacker.special_meter = min(MAX_SPECIAL, attacker.special_meter + 2.0)
		velocity.x = attacker.facing * 220.0
		hitstun = float(attack.get("blockstun", 0.16))
		state = State.BLOCK
		if health > 1.0:
			health = max(1.0, health - dmg)
			health_changed.emit(health, max_health)
		visual.pulse_hit()
		meters_changed.emit(special_meter, ultimate_meter)
		attacker.meters_changed.emit(attacker.special_meter, attacker.ultimate_meter)
		return

	var crit := false
	if attack.get("kind", "") == "heavy" and randf() < 0.18:
		crit = true
		dmg *= 1.35
	var scale := CombatRules.combo_scale(attacker.combo_hits)
	dmg *= scale
	health = max(0.0, health - dmg)
	var kb: float = float(attack.knockback)
	var launch: float = float(attack.launch)
	if not on_ground:
		kb *= 0.85
		launch = minf(launch, -120.0)
	velocity = Vector2(attacker.facing * kb, launch)
	hitstun = float(attack.hitstun)
	var hard_kd: bool = bool(attack.get("knockdown", false)) or health <= 0.0
	state = State.KNOCKDOWN if hard_kd else State.HIT
	visual.pulse_hit()
	attacker.last_attack_was_hit = true
	attacker.combo_hits += 1
	attacker.combo_decay = 1.1
	attacker.combo_changed.emit(attacker.combo_hits)
	attacker.special_meter = min(MAX_SPECIAL, attacker.special_meter + float(attack.meter))
	attacker.ultimate_meter = min(MAX_ULTIMATE, attacker.ultimate_meter + float(attack.meter) * 0.65)
	special_meter = min(MAX_SPECIAL, special_meter + 3.0)
	ultimate_meter = min(MAX_ULTIMATE, ultimate_meter + 2.2)
	var snd := "hit_h" if attack.get("kind", "") in ["heavy", "special", "ultimate"] else "hit_l"
	AudioDirector.play(snd, randf_range(0.92, 1.08))
	freeze_frames = float(attack.hitstop)
	attacker.freeze_frames = float(attack.hitstop) * 0.85
	health_changed.emit(health, max_health)
	meters_changed.emit(special_meter, ultimate_meter)
	attacker.meters_changed.emit(attacker.special_meter, attacker.ultimate_meter)
	hit_landed.emit(self, attack, crit)
	if health <= 0.0:
		defeated.emit(self)


func _face_opponent() -> void:
	if opponent == null:
		return
	if _busy_attack() or state in [State.HIT, State.KNOCKDOWN, State.VICTORY, State.DEFEAT, State.JUMP, State.PREJUMP, State.RUN, State.BACKDASH, State.GETUP]:
		return
	var dir := signf(opponent.position.x - position.x)
	if dir != 0:
		facing = int(dir)
		visual.facing = facing


func _sync_visual() -> void:
	if _busy_attack():
		visual.set_pose_name(str(current_attack.get("kind", "light")))
	else:
		match state:
			State.WALK:
				visual.set_pose_name("walk")
			State.RUN:
				visual.set_pose_name("run")
			State.BACKDASH:
				visual.set_pose_name("backdash")
			State.PREJUMP:
				visual.set_pose_name("prejump")
				visual.one_shot_u = 1.0 - clampf(_land_t / 0.05, 0.0, 1.0)
			State.JUMP:
				visual.set_pose_name("jump")
				var ju: float = clampf((velocity.y + 900.0) / 1800.0, 0.0, 1.0)
				visual.attack_u = ju
				if velocity.y < -420.0:
					visual.attack_u = lerpf(ju, 0.55, 0.35)
			State.LAND:
				visual.set_pose_name("land")
				visual.one_shot_u = 1.0 - clampf(_land_t / 0.12, 0.0, 1.0)
			State.GETUP:
				visual.set_pose_name("getup")
				visual.one_shot_u = 1.0 - clampf(_land_t / 0.18, 0.0, 1.0)
			State.CROUCH:
				visual.set_pose_name("crouch")
			State.BLOCK:
				visual.set_pose_name("block_hit" if hitstun > 0.0 and guarding else "block")
			State.HIT:
				if not on_ground or absf(velocity.y) > 120.0:
					visual.set_pose_name("air_hit" if velocity.y < 0.0 else "launch")
				else:
					visual.set_pose_name("hit")
				visual.one_shot_u = clampf(1.0 - hitstun / 0.35, 0.0, 1.0)
			State.KNOCKDOWN:
				visual.set_pose_name("knockdown")
			State.VICTORY:
				visual.set_pose_name("victory")
			State.DEFEAT:
				visual.set_pose_name("defeat")
			_:
				visual.set_pose_name("idle")
	var hs := hurtbox.get_child(0) as CollisionShape2D
	if state == State.CROUCH:
		(hs.shape as RectangleShape2D).size.y = 60 * def.height_scale
		hs.position.y = -32 * def.height_scale
	else:
		(hs.shape as RectangleShape2D).size.y = 96 * def.height_scale
		hs.position.y = -50 * def.height_scale


func _integrate(_delta: float) -> void:
	pass


func _separate_from_opponent() -> void:
	if opponent == null:
		return
	var dx := opponent.global_position.x - global_position.x
	if absf(dx) < 44.0 and absf(opponent.global_position.y - global_position.y) < 90.0:
		var push: float = (44.0 - absf(dx)) * 0.5
		var s := signf(dx)
		if s == 0.0:
			s = 1.0 if fighter_id == 0 else -1.0
		position.x -= s * push


func _keep_in_bounds() -> void:
	position.x = clamp(position.x, 80.0, 1200.0)
	if position.y > 900:
		position.y = 620
		velocity.y = 0


func distance_to_opponent() -> float:
	if opponent == null:
		return 9999.0
	return abs(opponent.position.x - position.x)
