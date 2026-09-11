class_name Projectile
extends Area2D

var owner_fighter: Fighter
var velocity: Vector2 = Vector2.ZERO
var life: float = 0.7
var kind: String = "bolt"
var accent: Color = Color.CYAN
var _hit := false


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
	var img := Pix.image(12, 8)
	if k == "ult":
		img = Pix.image(16, 12)
		Pix.rect(img, 1, 3, 14, 6, color)
		Pix.rect(img, 4, 1, 8, 10, color.lightened(0.2))
	else:
		Pix.rect(img, 1, 2, 10, 4, color)
		Pix.rect(img, 8, 1, 4, 6, color.lightened(0.25))
		Pix.put(img, 2, 3, Color.WHITE)
	Pix.outline(img, Color(0.05, 0.04, 0.06))
	var spr := Sprite2D.new()
	spr.texture = Pix.tex(img)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.scale = Vector2(4, 4)
	add_child(spr)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	life -= delta
	if life <= 0.0 or position.x < -40 or position.x > 1320:
		queue_free()


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
