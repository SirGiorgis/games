class_name FX
extends Node2D

var _overlay: CanvasLayer
var _flash: ColorRect


func _ready() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 18
	add_child(_overlay)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_overlay.add_child(_flash)


func super_flash(color: Color = Color.WHITE, dur: float = 0.35) -> void:
	_flash.color = Color(color, 0.72)
	var tw := _flash.create_tween()
	tw.tween_property(_flash, "color:a", 0.0, dur)


func spark(pos: Vector2, color: Color, strong: bool) -> void:
	_ring(pos, color, strong)
	var n := 16 if strong else 9
	for i in n:
		var img := Pix.image(2, 2, color if i % 2 == 0 else Color(1, 0.95, 0.55))
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(4, 4)
		s.global_position = pos + Vector2(randf_range(-6, 6), randf_range(-6, 6))
		add_child(s)
		var dir := Vector2(randf_range(-1, 1), randf_range(-1.15, -0.15)).normalized() * randf_range(110, 280 if strong else 170)
		var tw := s.create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(s, "position", s.position + dir * 0.22, 0.16)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.16)
		tw.tween_callback(s.queue_free)
	if strong:
		for i in 6:
			var bimg := Pix.image(3, 3, Color(0, 0, 0, 0))
			Pix.disc(bimg, 1, 1, 1, Color(0.62, 0.08, 0.10))
			var bs := Sprite2D.new()
			bs.texture = Pix.tex(bimg)
			bs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			bs.scale = Vector2(3, 3)
			bs.global_position = pos + Vector2(randf_range(-10, 10), randf_range(4, 18))
			add_child(bs)
			var bt := bs.create_tween()
			bt.tween_property(bs, "modulate:a", 0.0, 0.48)
			bt.tween_callback(bs.queue_free)
	var cross := Pix.image(9, 9, Color(0, 0, 0, 0))
	Pix.hline(cross, 0, 4, 9, Color(1, 0.94, 0.42, 1))
	Pix.vline(cross, 4, 0, 9, Color(1, 0.94, 0.42, 1))
	var cs := Sprite2D.new()
	cs.texture = Pix.tex(cross)
	cs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cs.scale = Vector2(3.2 if strong else 2.1, 3.2 if strong else 2.1)
	cs.global_position = pos
	add_child(cs)
	var ct := cs.create_tween()
	ct.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	ct.tween_property(cs, "modulate:a", 0.0, 0.12)
	ct.parallel().tween_property(cs, "scale", cs.scale * 1.85, 0.12)
	ct.tween_callback(cs.queue_free)
	_flash.color = Color(color, 0.18 if strong else 0.07)
	var ft := _flash.create_tween()
	ft.tween_property(_flash, "color:a", 0.0, 0.10)


func shade(dur: float = 0.45) -> void:
	_flash.color = Color(0.04, 0.02, 0.10, 0.48)
	var tw := _flash.create_tween()
	tw.tween_property(_flash, "color:a", 0.0, dur)


func shockwave(pos: Vector2) -> void:
	_ring(pos, Color(1, 0.92, 0.7), true)
	_ring(pos + Vector2(0, -8), Color(0.7, 0.85, 1.0), true)


func clash_burst(pos: Vector2) -> void:
	spark(pos, Color(1.0, 0.85, 0.4), true)
	shockwave(pos)


func crystals(pos: Vector2) -> void:
	for i in 10:
		var img := Pix.image(5, 7, Color(0, 0, 0, 0))
		Pix.vline(img, 2, 0, 7, Color(0.75, 0.95, 1.0))
		Pix.put(img, 1, 2, Color(0.9, 0.98, 1.0))
		Pix.put(img, 3, 3, Color(0.65, 0.88, 1.0))
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(3, 3)
		s.centered = true
		s.global_position = pos + Vector2(randf_range(-22, 22), randf_range(-18, 8))
		add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "position:y", s.position.y - randf_range(18, 40), 0.38)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.38)
		tw.parallel().tween_property(s, "rotation", randf_range(-0.8, 0.8), 0.38)
		tw.tween_callback(s.queue_free)


func quake_dust(pos: Vector2) -> void:
	shockwave(pos + Vector2(0, 40))
	for i in 12:
		var img := Pix.image(4, 3, Color(0, 0, 0, 0))
		Pix.disc(img, 1, 1, 1, Color(0.45, 0.32, 0.16, 0.85))
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(4, 4)
		s.centered = true
		s.global_position = pos + Vector2(randf_range(-80, 80), randf_range(8, 24))
		add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "position:y", s.position.y - 16.0, 0.32)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.32)
		tw.tween_callback(s.queue_free)


func letterbox(dur: float = 0.5) -> void:
	for y in [0.0, 656.0]:
		var bar := ColorRect.new()
		bar.color = Color(0, 0, 0, 0.78)
		bar.position = Vector2(0, y)
		bar.size = Vector2(1280, 64)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.add_child(bar)
		var tw := bar.create_tween()
		tw.tween_interval(dur)
		tw.tween_property(bar, "modulate:a", 0.0, 0.18)
		tw.tween_callback(bar.queue_free)


func burst_ring(pos: Vector2) -> void:
	shockwave(pos)
	spark(pos, Color(0.95, 0.85, 1.0), true)


func vodka_glug(pos: Vector2) -> void:
	shockwave(pos + Vector2(0, -8))
	for i in 12:
		var img := Pix.image(3, 5, Color(0, 0, 0, 0))
		var col := Color(0.78, 0.95, 0.88) if i % 2 == 0 else Color(0.92, 0.96, 1.0)
		Pix.vline(img, 1, 0, 5, col)
		Pix.put(img, 1, 4, Color(0.55, 0.78, 0.70))
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(3, 3)
		s.centered = true
		s.global_position = pos + Vector2(randf_range(-18, 18), randf_range(-24, 6))
		add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "position:y", s.position.y - randf_range(20, 44), 0.42)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.42)
		tw.tween_callback(s.queue_free)


func dempsey_burst(pos: Vector2) -> void:
	spark(pos, Color(0.95, 0.72, 0.38), true)
	for i in 8:
		var img := Pix.image(6, 4, Color(0, 0, 0, 0))
		Pix.disc(img, 2, 2, 2, Color(0.95, 0.82, 0.55))
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(3, 3)
		s.centered = true
		var side: float = -1.0 if i % 2 == 0 else 1.0
		s.global_position = pos + Vector2(side * randf_range(8, 28), randf_range(-22, 10))
		add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "position:x", s.position.x + side * 36.0, 0.18)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.18)
		tw.tween_callback(s.queue_free)


func grid_streaks(pos: Vector2, facing: int = 1) -> void:
	shockwave(pos)
	var car: Image = Projectile.art_for("car", Color(0.78, 0.08, 0.10))
	for i in 3:
		var s := Sprite2D.new()
		s.texture = Pix.tex(car)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(4, 4)
		s.centered = true
		s.flip_h = facing < 0
		s.global_position = pos + Vector2(float(facing) * (-20.0 - float(i) * 18.0), -6.0 + float(i) * 10.0)
		s.modulate = Color(1, 1, 1, 0.55)
		add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "position:x", s.position.x + float(facing) * 220.0, 0.28)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.28)
		tw.tween_callback(s.queue_free)


func popup(pos: Vector2, text: String, color: Color) -> void:
	var spr := Sprite2D.new()
	spr.texture = PixelFont.make(text, color, 2)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.centered = true
	spr.global_position = pos + Vector2(0, -90)
	spr.z_index = 8
	add_child(spr)
	var tw := spr.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(spr, "global_position:y", spr.global_position.y - 28.0, 0.38)
	tw.parallel().tween_property(spr, "modulate:a", 0.0, 0.38)
	tw.tween_callback(spr.queue_free)


func _ring(pos: Vector2, color: Color, strong: bool) -> void:
	var img := Pix.image(17, 17, Color(0, 0, 0, 0))
	Pix.disc(img, 8, 8, 7, Color(color, 0.0))
	for a in 16:
		var ang: float = float(a) / 16.0 * TAU
		var x: int = 8 + int(round(cos(ang) * 6.0))
		var y: int = 8 + int(round(sin(ang) * 6.0))
		Pix.put(img, x, y, Color(1, 0.95, 0.7, 0.95))
		Pix.put(img, x, y, color)
	var s := Sprite2D.new()
	s.texture = Pix.tex(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = true
	s.global_position = pos
	s.scale = Vector2(2.2 if strong else 1.6, 2.2 if strong else 1.6)
	add_child(s)
	var tw := s.create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(s, "scale", s.scale * (2.4 if strong else 1.9), 0.16)
	tw.parallel().tween_property(s, "modulate:a", 0.0, 0.16)
	tw.tween_callback(s.queue_free)
