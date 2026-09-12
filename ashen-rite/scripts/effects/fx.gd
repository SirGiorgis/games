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


func spark(pos: Vector2, color: Color, strong: bool) -> void:
	var n := 14 if strong else 8
	for i in n:
		var img := Pix.image(2, 2, color if i % 2 == 0 else Color(1, 0.95, 0.55))
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(4, 4)
		s.global_position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		add_child(s)
		var dir := Vector2(randf_range(-1, 1), randf_range(-1.2, -0.2)).normalized() * randf_range(90, 260 if strong else 160)
		var tw := s.create_tween()
		tw.tween_property(s, "position", s.position + dir * 0.25, 0.18)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.18)
		tw.tween_callback(s.queue_free)
	# Tiny Fight-style blood specks
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
			bt.tween_property(bs, "modulate:a", 0.0, 0.55)
			bt.tween_callback(bs.queue_free)
	var cross := Pix.image(9, 9, Color(0, 0, 0, 0))
	Pix.hline(cross, 0, 4, 9, Color(1, 0.92, 0.4, 1))
	Pix.vline(cross, 4, 0, 9, Color(1, 0.92, 0.4, 1))
	var cs := Sprite2D.new()
	cs.texture = Pix.tex(cross)
	cs.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cs.scale = Vector2(3 if strong else 2, 3 if strong else 2)
	cs.global_position = pos
	add_child(cs)
	var ct := cs.create_tween()
	ct.tween_property(cs, "modulate:a", 0.0, 0.14)
	ct.parallel().tween_property(cs, "scale", cs.scale * 1.6, 0.14)
	ct.tween_callback(cs.queue_free)
	_flash.color = Color(color, 0.22 if strong else 0.08)
	var ft := _flash.create_tween()
	ft.tween_property(_flash, "color:a", 0.0, 0.12)
