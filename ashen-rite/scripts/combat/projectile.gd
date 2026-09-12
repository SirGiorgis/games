class_name Projectile
extends Area2D

var owner_fighter: Fighter
var velocity: Vector2 = Vector2.ZERO
var life: float = 0.7
var kind: String = "bolt"
var accent: Color = Color.CYAN
var pierce: bool = false
var freeze: bool = false
var _spr: Sprite2D
var _trail := 0.0
var _hit_ids: Dictionary = {}


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
	c.radius = 16.0
	if k == "ult":
		c.radius = 28.0
	elif k == "void":
		c.radius = 14.0
	elif k == "ice":
		c.radius = 18.0
	elif k == "car":
		c.radius = 20.0
	cs.shape = c
	add_child(cs)
	area_entered.connect(_on_area)
	_spr = Sprite2D.new()
	_spr.texture = Pix.tex(art_for(k, color))
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.scale = Vector2(4, 4)
	if k == "car":
		_spr.scale = Vector2(5, 5)
	add_child(_spr)


static func art_for(k: String, color: Color) -> Image:
	var img: Image
	match k:
		"ult":
			img = Pix.image(16, 12, Color(0, 0, 0, 0))
			Pix.disc(img, 8, 6, 6, color)
			Pix.disc(img, 8, 6, 3, Color(1, 0.95, 0.8))
			Pix.rect(img, 1, 4, 14, 4, color.lightened(0.15))
		"wave":
			img = Pix.image(14, 10, Color(0, 0, 0, 0))
			Pix.hline(img, 1, 4, 12, color)
			Pix.hline(img, 2, 3, 10, color.lightened(0.25))
			Pix.hline(img, 2, 6, 10, color.darkened(0.1))
			Pix.put(img, 12, 4, Color.WHITE)
		"void":
			img = Pix.image(10, 10, Color(0, 0, 0, 0))
			Pix.disc(img, 5, 5, 4, Color(0.18, 0.08, 0.28))
			Pix.disc(img, 5, 5, 2, color)
			Pix.put(img, 5, 5, Color.WHITE)
		"ice":
			img = Pix.image(12, 12, Color(0, 0, 0, 0))
			Pix.disc(img, 6, 6, 5, color)
			Pix.vline(img, 6, 1, 10, Color(0.92, 0.98, 1.0))
			Pix.hline(img, 2, 6, 8, Color(0.85, 0.95, 1.0, 0.8))
		"car":
			img = _car_art(color)
		_:
			img = Pix.image(12, 8, Color(0, 0, 0, 0))
			Pix.rect(img, 1, 2, 10, 4, color)
			Pix.rect(img, 8, 1, 4, 6, color.lightened(0.25))
			Pix.put(img, 2, 3, Color.WHITE)
	if k != "car":
		Pix.outline(img, Color(0.05, 0.04, 0.06))
	return img


static func _car_art(color: Color) -> Image:
	# Original open-wheel racer. Rosso body, yellow CX roundel. No team badges.
	var img := Pix.image(26, 12, Color(0, 0, 0, 0))
	var body: Color = Color(0.78, 0.08, 0.10) if color.r > 0.4 else color
	var body_hi: Color = body.lightened(0.16)
	var body_dk: Color = body.darkened(0.22)
	var wing: Color = Color(0.12, 0.11, 0.12)
	var yellow := Color(0.96, 0.78, 0.12)
	var tire := Color(0.08, 0.08, 0.09)
	var rim := Color(0.62, 0.62, 0.66)
	# rear wing
	Pix.rect(img, 1, 1, 5, 2, wing)
	Pix.vline(img, 3, 3, 3, wing)
	# nose + front wing
	Pix.rect(img, 18, 4, 7, 2, body)
	Pix.rect(img, 21, 3, 4, 1, yellow)
	Pix.rect(img, 20, 6, 6, 1, wing)
	Pix.hline(img, 19, 7, 7, wing)
	# chassis
	Pix.rect(img, 5, 3, 16, 4, body)
	Pix.rect(img, 7, 2, 11, 2, body_hi)
	Pix.rect(img, 6, 6, 13, 1, body_dk)
	# cockpit bubble
	Pix.rect(img, 10, 1, 6, 3, Color(0.18, 0.22, 0.28))
	Pix.rect(img, 11, 1, 4, 2, Color(0.55, 0.72, 0.88))
	Pix.put(img, 12, 2, Color(0.85, 0.92, 1.0))
	# original CX roundel on the side (not a licensed badge)
	Pix.disc(img, 16, 5, 2, yellow)
	Pix.put(img, 15, 4, Color(0.12, 0.10, 0.10))
	Pix.put(img, 16, 5, Color(0.12, 0.10, 0.10))
	Pix.put(img, 17, 4, Color(0.12, 0.10, 0.10))
	Pix.put(img, 17, 6, Color(0.12, 0.10, 0.10))
	# wheels
	Pix.rect(img, 4, 7, 4, 4, tire)
	Pix.rect(img, 5, 8, 2, 2, rim)
	Pix.rect(img, 18, 7, 4, 4, tire)
	Pix.rect(img, 19, 8, 2, 2, rim)
	Pix.outline(img, Color(0.05, 0.04, 0.06))
	return img


func _physics_process(delta: float) -> void:
	position += velocity * delta
	if kind == "ice":
		velocity.y += 420.0 * delta
	life -= delta
	if _spr:
		if kind == "car":
			_spr.rotation = 0.0
			_spr.flip_h = velocity.x < 0.0
			_spr.scale = Vector2(5.0, 5.0)
		else:
			var spin: float = 10.0 if kind == "void" else 8.0
			_spr.rotation += delta * spin * signf(velocity.x if velocity.x != 0.0 else 1.0)
			_spr.scale = Vector2(4.0 + sin(life * 18.0) * 0.35, 4.0)
	_trail -= delta
	if _trail <= 0.0:
		_trail = 0.045
		_ghost()
	if life <= 0.0 or position.x < -40 or position.x > 1320 or position.y > 760:
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
	g.flip_h = _spr.flip_h
	g.modulate = Color(accent, 0.35)
	g.z_index = -1
	var p := get_parent()
	if p:
		p.add_child(g)
		var tw := g.create_tween()
		tw.tween_property(g, "modulate:a", 0.0, 0.12)
		tw.tween_callback(g.queue_free)


func _on_area(area: Area2D) -> void:
	var fid = area.get_meta("fighter_id", -1)
	if owner_fighter and fid == owner_fighter.fighter_id:
		return
	if _hit_ids.has(fid):
		return
	_hit_ids[fid] = true
	var other := area.get_parent()
	while other and not (other is Fighter):
		other = other.get_parent()
	if other is Fighter:
		var atk: Dictionary
		if kind == "ult" or kind == "car" or kind == "void":
			atk = CombatRules.make_attack("ultimate", owner_fighter.def)
		else:
			atk = CombatRules.make_attack("special", owner_fighter.def)
			atk.damage *= 0.85
		atk.projectile = ""
		if freeze or kind == "ice":
			atk.freeze = true
		(other as Fighter).receive_hit(owner_fighter, atk)
	if not pierce:
		queue_free()
