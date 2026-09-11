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
	var n := 10 if strong else 6
	for i in n:
		var img := Pix.image(2, 2, color)
		var s := Sprite2D.new()
		s.texture = Pix.tex(img)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.scale = Vector2(4, 4)
		s.global_position = pos + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		add_child(s)
		var dir := Vector2(randf_range(-1, 1), randf_range(-1.2, -0.2)).normalized() * randf_range(80, 220 if strong else 140)
		var tw := s.create_tween()
		tw.tween_property(s, "position", s.position + dir * 0.25, 0.22)
		tw.parallel().tween_property(s, "modulate:a", 0.0, 0.22)
		tw.tween_callback(s.queue_free)
	_flash.color = Color(color, 0.22 if strong else 0.08)
	var ft := _flash.create_tween()
	ft.tween_property(_flash, "color:a", 0.0, 0.12)
