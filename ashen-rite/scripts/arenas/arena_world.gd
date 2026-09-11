class_name ArenaWorld
extends Node2D

const FLOOR_Y := 620.0
const WIDTH := 1280.0

var arena_id: String = "moonlit_temple"


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
	var col := Color(0.7, 0.75, 1.0, 0.5)
	if id == "neon_street":
		col = Color(0.9, 0.3, 0.7, 0.45)
	elif id == "the_pit":
		col = Color(0.9, 0.3, 0.15, 0.5)
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
