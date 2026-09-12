class_name CottonPickup
extends Node2D
## Ground boll. Only the fighter who spawned it can collect it.

const HEAL := 52.0
const DRAIN := 38.0
const REACH := 36.0

var owner_fighter: Fighter
var life: float = 7.0
var _armed := false
var _arm_t := 0.42
var _spr: Sprite2D
var _bob := 0.0
var _taken := false


func setup(source: Fighter, x: float) -> void:
	owner_fighter = source
	position = Vector2(x, ArenaWorld.FLOOR_Y - 4.0)
	z_index = 3
	add_to_group("cotton_pickup")
	_spr = Sprite2D.new()
	_spr.texture = Pix.tex(Pix.cotton())
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.scale = Vector2(4, 4)
	_spr.centered = true
	add_child(_spr)


func _physics_process(delta: float) -> void:
	if _taken:
		return
	_bob += delta * 7.0
	if _spr:
		_spr.position.y = sin(_bob) * 3.0
		_spr.rotation = sin(_bob * 0.7) * 0.12
	_arm_t = maxf(0.0, _arm_t - delta)
	if _arm_t <= 0.0:
		_armed = true
	life -= delta
	if life <= 0.0 or owner_fighter == null or not is_instance_valid(owner_fighter) or owner_fighter.round_over:
		_expire()
		return
	if not _armed:
		return
	if not _can_collect(owner_fighter):
		return
	if absf(owner_fighter.global_position.x - global_position.x) <= REACH:
		_collect()


func _can_collect(f: Fighter) -> bool:
	if f.health <= 0.0 or f.round_over:
		return false
	if not f.on_ground:
		return false
	if f.state in [Fighter.State.HIT, Fighter.State.KNOCKDOWN, Fighter.State.ULTIMATE, Fighter.State.DEFEAT, Fighter.State.VICTORY]:
		return false
	return true


func _collect() -> void:
	if _taken:
		return
	_taken = true
	if is_in_group("cotton_pickup"):
		remove_from_group("cotton_pickup")
	var f := owner_fighter
	f.cotton_left = maxi(0, f.cotton_left - 1)
	f.health = minf(f.max_health, f.health + HEAL)
	f.health_changed.emit(f.health, f.max_health)
	var foe: Fighter = f.opponent
	if foe and foe.health > 0.0 and not foe.round_over:
		foe.health = maxf(0.0, foe.health - DRAIN)
		foe.health_changed.emit(foe.health, foe.max_health)
		if foe.visual:
			foe.visual.pulse_hit()
		if foe.health <= 0.0:
			foe.defeated.emit(foe)
	f.announced.emit("COTTON")
	AudioDirector.play("meter", 1.15, 0.65)
	if f.visual:
		f.visual.dust()
		f.visual.punch_impact(0.55)
	queue_free()


func discard() -> void:
	_taken = true
	if is_in_group("cotton_pickup"):
		remove_from_group("cotton_pickup")
	queue_free()


func _expire() -> void:
	if _taken:
		return
	_taken = true
	if is_in_group("cotton_pickup"):
		remove_from_group("cotton_pickup")
	if owner_fighter and is_instance_valid(owner_fighter):
		owner_fighter.cotton_left = maxi(0, owner_fighter.cotton_left - 1)
	queue_free()
