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
	var p := CPUParticles2D.new()
	p.global_position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 18 if strong else 10
	p.lifetime = 0.28
	p.direction = Vector2(0, -1)
	p.spread = 80
	p.initial_velocity_min = 80
	p.initial_velocity_max = 220 if strong else 140
	p.gravity = Vector2(0, 400)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0 if strong else 3.0
	p.color = color
	add_child(p)
	get_tree().create_timer(0.45).timeout.connect(p.queue_free)
	_flash.color = Color(color, 0.22 if strong else 0.08)
	var tw := _flash.create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.12)


func finish_stamp(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.add_theme_font_size_override("font_size", 84)
	l.add_theme_color_override("font_color", Color(1, 0.85, 0.35))
	l.add_theme_color_override("font_outline_color", Color(0.2, 0, 0))
	l.add_theme_constant_override("outline_size", 10)
	return l
