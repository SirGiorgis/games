class_name ArenaWorld
extends Node2D

const FLOOR_Y := 620.0
const WIDTH := 1280.0

var arena_id: String = "grass_field"


func build(id: String) -> void:
	arena_id = id
	for c in get_children():
		c.queue_free()
	var bg := Sprite2D.new()
	bg.texture = PixelArenaBake.texture(id)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg.centered = false
	bg.scale = Vector2(PixelArenaBake.SCALE, PixelArenaBake.SCALE)
	bg.position = Vector2(0, 0)
	bg.z_index = -10
	add_child(bg)
	_dust(id)
	_weather(id)
	_crowd()
	_birds()
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


func _dust(id: String) -> void:
	var col := Color(0.85, 0.9, 0.55, 0.35)
	if id == "neon_street":
		col = Color(0.9, 0.3, 0.7, 0.45)
	elif id == "the_pit":
		col = Color(0.9, 0.3, 0.15, 0.5)
	elif id == "grass_field":
		col = Color(0.7, 0.82, 0.4, 0.28)
	var parts := CPUParticles2D.new()
	parts.position = Vector2(640, 240)
	parts.emitting = true
	parts.amount = 28
	parts.lifetime = 3.5
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	parts.emission_rect_extents = Vector2(640, 160)
	parts.direction = Vector2(0.15, 1)
	parts.gravity = Vector2(0, 18)
	parts.initial_velocity_min = 4
	parts.initial_velocity_max = 14
	parts.scale_amount_min = 2
	parts.scale_amount_max = 4
	parts.color = col
	var pimg := Pix.image(2, 2, col)
	parts.texture = Pix.tex(pimg)
	parts.z_index = -1
	add_child(parts)


func _weather(id: String) -> void:
	var parts := CPUParticles2D.new()
	parts.position = Vector2(640, 70)
	parts.emitting = true
	parts.amount = 34
	parts.lifetime = 4.0
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	parts.emission_rect_extents = Vector2(640, 36)
	parts.direction = Vector2(0.4, 1)
	parts.gravity = Vector2(14, 26)
	parts.initial_velocity_min = 8
	parts.initial_velocity_max = 20
	parts.scale_amount_min = 1.5
	parts.scale_amount_max = 3.0
	var col := Color(0.52, 0.70, 0.26, 0.5)
	if id == "moonlit_temple":
		col = Color(0.84, 0.92, 1.0, 0.7)
		parts.gravity = Vector2(4, 10)
	elif id == "neon_street":
		col = Color(0.95, 0.28, 0.78, 0.5)
		parts.gravity = Vector2(0, 6)
	elif id == "the_pit":
		col = Color(1.0, 0.38, 0.12, 0.62)
		parts.gravity = Vector2(-6, -16)
		parts.direction = Vector2(0, -1)
	elif id == "crimson_keep":
		col = Color(0.58, 0.14, 0.14, 0.48)
	parts.color = col
	parts.texture = Pix.tex(Pix.image(2, 2, col))
	parts.z_index = -1
	add_child(parts)


func _crowd() -> void:
	for i in 10:
		var img := Pix.image(4, 6, Color(0, 0, 0, 0))
		var shade := 0.10 + float(i % 5) * 0.03
		Pix.rect(img, 1, 2, 2, 4, Color(shade, shade * 0.8, shade * 0.9, 0.7))
		Pix.put(img, 1, 1, Color(shade + 0.08, shade * 0.7, shade * 0.7, 0.8))
		Pix.put(img, 2, 1, Color(shade + 0.08, shade * 0.7, shade * 0.7, 0.8))
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(4, 4)
		s.centered = false
		var left: bool = i < 5
		var idx: int = i % 5
		s.position = Vector2((80.0 + idx * 26.0) if left else (1088.0 + idx * 26.0), 536.0)
		s.z_index = -3
		s.set_meta("bob", 1.1 + idx * 0.4)
		s.set_meta("base_y", s.position.y)
		add_child(s)


func _birds() -> void:
	for i in 6:
		var b := Sprite2D.new()
		var img := Pix.image(5, 3, Color(0, 0, 0, 0))
		Pix.put(img, 1, 1, Color(0.12, 0.12, 0.14, 0.85))
		Pix.put(img, 2, 1, Color(0.18, 0.18, 0.2, 0.9))
		Pix.put(img, 3, 1, Color(0.12, 0.12, 0.14, 0.85))
		Pix.put(img, 0, 0, Color(0.16, 0.16, 0.18, 0.7))
		Pix.put(img, 4, 0, Color(0.16, 0.16, 0.18, 0.7))
		b.texture = Pix.tex(img)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.scale = Vector2(3, 3)
		b.position = Vector2(80.0 + i * 190.0, 82.0 + float(i % 3) * 26.0)
		b.z_index = -2
		b.set_meta("spd", 18.0 + float(i) * 7.0)
		b.set_meta("base_y", b.position.y)
		add_child(b)


func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	for c in get_children():
		if c is Sprite2D and c.has_meta("spd"):
			var s: Sprite2D = c
			s.position.x += float(s.get_meta("spd")) * delta
			s.position.y = float(s.get_meta("base_y")) + sin(s.position.x * 0.04) * 6.0
			if s.position.x > 1320.0:
				s.position.x = -30.0
		elif c is Sprite2D and c.has_meta("bob"):
			var b: Sprite2D = c
			b.position.y = float(b.get_meta("base_y")) + sin(t * float(b.get_meta("bob"))) * 3.0


static func all_ids() -> PackedStringArray:
	return PackedStringArray(["grass_field", "moonlit_temple", "neon_street", "the_pit", "crimson_keep"])


static func display_name(id: String) -> String:
	match id:
		"neon_street":
			return "NEON RIFT STREET"
		"the_pit":
			return "THE UNDER-RITE"
		"crimson_keep":
			return "CRIMSON KEEP"
		"moonlit_temple":
			return "MOONLIT TEMPLE"
		_:
			return "GREEN HILL FIELD"
