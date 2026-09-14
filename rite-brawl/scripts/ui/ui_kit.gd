class_name UIKit
extends RefCounted

const BG := Color(0.05, 0.03, 0.07, 0.92)
const GOLD := Color(0.9, 0.74, 0.32)
const RED := Color(0.82, 0.16, 0.22)
const TEAL := Color(0.35, 0.85, 0.9)


static func title_font(size: int) -> int:
	return size


static func style_label(l: Label, size: int, color: Color = Color(0.95, 0.92, 0.88)) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)


static func make_button_label(text: String, selected: bool) -> String:
	if selected:
		return "▸  %s  ◂" % text
	return "   %s" % text
