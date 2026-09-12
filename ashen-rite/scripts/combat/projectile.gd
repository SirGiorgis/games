class_name Projectile
extends Area2D

var owner_fighter: Fighter
var velocity: Vector2 = Vector2.ZERO
var life: float = 0.7
var kind: String = "bolt"
var accent: Color = Color.CYAN
var _hit := false
var _spr: Sprite2D
var _trail := 0.0


func setup(source: Fighter, k: String, color: Color) -> void:
	owner_fighter = source
	kind = k
	accent = color
	collision_layer = 4
	collision_mask = 8
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 16.0 if k != "ult" else 28.0
	cs.shape = c
	add_child(cs)
	area_entered.connect(_on_area)
	var img: Image
	if k == "ult":
		img = Pix.image(16, 12, Color(0, 0, 0, 0))
		Pix.disc(img, 8, 6, 6, color)
		Pix.disc(img, 8, 6, 3, Color(1, 0.95, 0.8))
		Pix.rect(img, 1, 4, 14, 4, color.lightened(0.15))
	elif k == "wave":
		img = Pix.image(14, 10, Color(0, 0, 0, 0))
		Pix.hline(img, 1, 4, 12, color)
		Pix.hline(img, 2, 3, 10, color.lightened(0.25))
		Pix.hline(img, 2, 6, 10, color.darkened(0.1))
		Pix.put(img, 12, 4, Color.WHITE)
	else:
		img = Pix.image(12, 8, Color(0, 0, 0, 0))
		Pix.rect(img, 1, 2, 10, 4, color)
		Pix.rect(img, 8, 1, 4, 6, color.lightened(0.25))
		Pix.put(img, 2, 3, Color.WHITE)
	Pix.outline(img, Color(0.05, 0.04, 0.06))
	_spr = Sprite2D.new()
	_spr.texture = Pix.tex(img)
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.scale = Vector2(4, 4)
	add_child(_spr)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if _spr:
		_spr.rotation += delta * 8.0 * signf(velocity.x)
		_spr.scale = Vector2(4.0 + sin(life * 18.0) * 0.35, 4.0)
	_trail -= delta
	if _trail <= 0.0:
		_trail = 0.05
		_ghost()
	if life <= 0.0 or position.x < -40 or position.x > 1320:
		queue_free()


func _ghost() -> void:
	if _spr == null or _spr.texture == null:
		return
	var g := Sprite2D.new()
	g.texture = _spr.texture
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.global_position = _spr.global_position
	g.scale = _spr.scale
	g.rotation = _spr.rotation
	g.modulate = Color(accent, 0.35)
	g.z_index = -1
	var p := get_parent()
	if p:
		p.add_child(g)
		var tw := g.create_tween()
		tw.tween_property(g, "modulate:a", 0.0, 0.12)
		tw.tween_callback(g.queue_free)


func _on_area(area: Area2D) -> void:
	if _hit:
		return
	var fid = area.get_meta("fighter_id", -1)
	if owner_fighter and fid == owner_fighter.fighter_id:
		return
	_hit = true
	var other := area.get_parent()
	while other and not (other is Fighter):
		other = other.get_parent()
	if other is Fighter:
		var atk := CombatRules.make_attack("special", owner_fighter.def)
		atk.damage *= 0.85
		if kind == "ult":
			atk = CombatRules.make_attack("ultimate", owner_fighter.def)
		(other as Fighter).receive_hit(owner_fighter, atk)
	queue_free()
