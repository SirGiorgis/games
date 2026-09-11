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
	var poly := Polygon2D.new()
	var pts: Array = []
	var n := 8
	for i in n:
		var a := TAU * i / n
		var r := 14.0 if i % 2 == 0 else 8.0
		if k == "wave":
			r = 10.0 if i % 2 == 0 else 22.0
		if k == "ult":
			r *= 1.7
		pts.append(Vector2(cos(a), sin(a)) * r)
	poly.polygon = PackedVector2Array(pts)
	poly.color = Color(color, 0.9)
	add_child(poly)
	var parts := CPUParticles2D.new()
	parts.emitting = true
	parts.amount = 20
	parts.lifetime = 0.35
	parts.direction = Vector2(-signf(velocity.x if velocity.x != 0.0 else 1.0), 0)
	parts.spread = 40
	parts.initial_velocity_min = 20
	parts.initial_velocity_max = 80
	parts.color = color
	add_child(parts)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	rotation += delta * 8.0
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
