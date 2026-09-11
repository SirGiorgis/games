class_name ArenaWorld
extends Node2D

const FLOOR_Y := 620.0
const WIDTH := 1280.0

var arena_id: String = "moonlit_temple"
var _particles: Array[CPUParticles2D] = []


func build(id: String) -> void:
	arena_id = id
	for c in get_children():
		c.queue_free()
	_particles.clear()
	match id:
		"neon_street":
			_neon()
		"the_pit":
			_pit()
		"crimson_keep":
			_keep()
		_:
			_temple()
	_ground()
	_walls()


func _ground() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(1600, 80)
	cs.shape = rect
	cs.position = Vector2(640, FLOOR_Y + 40)
	body.add_child(cs)
	add_child(body)
	var vis := ColorRect.new()
	vis.size = Vector2(1280, 100)
	vis.position = Vector2(0, FLOOR_Y)
	vis.color = Color(0.07, 0.06, 0.08, 1)
	vis.z_index = 2
	add_child(vis)
	var line := ColorRect.new()
	line.size = Vector2(1280, 3)
	line.position = Vector2(0, FLOOR_Y)
	line.color = Color(0.9, 0.75, 0.35, 0.7)
	line.z_index = 3
	add_child(line)


func _walls() -> void:
	for x in [40.0, 1240.0]:
		var b := StaticBody2D.new()
		b.collision_layer = 1
		var cs := CollisionShape2D.new()
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 900)
		cs.shape = r
		cs.position = Vector2(x, 300)
		b.add_child(cs)
		add_child(b)


func _rect(pos: Vector2, size: Vector2, color: Color, z: int = 0) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.z_index = z
	add_child(r)
	return r


func _temple() -> void:
	_rect(Vector2(0, 0), Vector2(1280, 720), Color(0.03, 0.04, 0.1))
	_rect(Vector2(0, 80), Vector2(1280, 220), Color(0.05, 0.07, 0.16), -8)
	_moon(Vector2(980, 110), 48, Color(0.75, 0.82, 1.0, 0.85))
	for i in 5:
		var h := 180 + i * 18
		_rect(Vector2(90 + i * 230, FLOOR_Y - h), Vector2(46, h), Color(0.12, 0.1, 0.16), -4)
		_rect(Vector2(90 + i * 230, FLOOR_Y - h - 24), Vector2(46, 24), Color(0.28, 0.18, 0.12), -4)
	_rect(Vector2(200, 200), Vector2(880, 16), Color(0.35, 0.22, 0.12), -3)
	_dust(Color(0.45, 0.55, 0.9, 0.35), 0.2)


func _neon() -> void:
	_rect(Vector2(0, 0), Vector2(1280, 720), Color(0.05, 0.02, 0.08))
	_rect(Vector2(0, 260), Vector2(1280, 360), Color(0.08, 0.03, 0.12), -8)
	for i in 8:
		var x := 40 + i * 160
		_rect(Vector2(x, 80), Vector2(70, 420), Color(0.08, 0.08, 0.12), -6)
		_rect(Vector2(x + 8, 120 + (i % 3) * 40), Vector2(54, 18), Color(0.1, 0.9, 0.85, 0.7) if i % 2 == 0 else Color(0.95, 0.2, 0.55, 0.7), -5)
	_rect(Vector2(0, FLOOR_Y - 8), Vector2(1280, 8), Color(0.2, 0.9, 0.85, 0.4), -2)
	_dust(Color(0.9, 0.2, 0.7, 0.4), 0.45)


func _pit() -> void:
	_rect(Vector2(0, 0), Vector2(1280, 720), Color(0.04, 0.03, 0.03))
	_rect(Vector2(0, 40), Vector2(1280, 140), Color(0.12, 0.04, 0.04), -8)
	for i in 6:
		_rect(Vector2(60 + i * 210, 180), Vector2(24, FLOOR_Y - 180), Color(0.18, 0.08, 0.07), -5)
	_rect(Vector2(300, 240), Vector2(680, 12), Color(0.5, 0.12, 0.1), -4)
	_dust(Color(0.9, 0.25, 0.12, 0.5), 0.7)


func _keep() -> void:
	_rect(Vector2(0, 0), Vector2(1280, 720), Color(0.06, 0.05, 0.07))
	_rect(Vector2(0, 90), Vector2(1280, 200), Color(0.16, 0.08, 0.1), -8)
	_moon(Vector2(180, 100), 36, Color(0.9, 0.55, 0.4, 0.7))
	for i in 4:
		_rect(Vector2(140 + i * 280, 220), Vector2(90, FLOOR_Y - 220), Color(0.14, 0.12, 0.14), -5)
		_rect(Vector2(150 + i * 280, 250), Vector2(28, 40), Color(0.05, 0.04, 0.05), -4)
		_rect(Vector2(192 + i * 280, 250), Vector2(28, 40), Color(0.05, 0.04, 0.05), -4)
	_rect(Vector2(80, 200), Vector2(1120, 18), Color(0.22, 0.12, 0.12), -3)
	_dust(Color(0.7, 0.5, 0.35, 0.35), 0.3)


func _moon(pos: Vector2, r: float, color: Color) -> void:
	var p := Polygon2D.new()
	var pts: Array = []
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(pos + Vector2(cos(a), sin(a)) * r)
	p.polygon = PackedVector2Array(pts)
	p.color = color
	p.z_index = -7
	add_child(p)


func _dust(color: Color, grav: float) -> void:
	var parts := CPUParticles2D.new()
	parts.position = Vector2(640, 200)
	parts.emitting = true
	parts.amount = 40
	parts.lifetime = 4.0
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	parts.emission_rect_extents = Vector2(640, 180)
	parts.direction = Vector2(0.2, 1)
	parts.spread = 20
	parts.gravity = Vector2(0, 12 * grav)
	parts.initial_velocity_min = 4
	parts.initial_velocity_max = 18
	parts.scale_amount_min = 1.2
	parts.scale_amount_max = 2.8
	parts.color = color
	parts.z_index = -1
	add_child(parts)
	_particles.append(parts)


static func all_ids() -> PackedStringArray:
	return PackedStringArray(["moonlit_temple", "neon_street", "the_pit", "crimson_keep"])


static func display_name(id: String) -> String:
	match id:
		"neon_street":
			return "NEON RIFT STREET"
		"the_pit":
			return "THE UNDER-RITE"
		"crimson_keep":
			return "CRIMSON KEEP"
		_:
			return "MOONLIT TEMPLE"
