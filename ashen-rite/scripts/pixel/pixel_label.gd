class_name PixelLabel
extends TextureRect

var px_scale: int = 2
var px_color: Color = Color(0.95, 0.92, 0.86)
var wrap_cols: int = 0
var _raw: String = ""


func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch_mode = STRETCH_KEEP
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = EXPAND_IGNORE_SIZE


func set_pix(text: String, scale: int = 2, color: Color = Color(0.95, 0.92, 0.86), wrap: int = 0) -> void:
	px_scale = scale
	px_color = color
	wrap_cols = wrap
	_raw = text
	texture = PixelFont.make(text, color, scale, wrap)
	if texture:
		custom_minimum_size = texture.get_size()
		size = texture.get_size()


func set_centered(total_width: int) -> void:
	if texture == null:
		return
	size = Vector2(total_width, texture.get_height())
	custom_minimum_size = size
	stretch_mode = STRETCH_KEEP_CENTERED
	expand_mode = EXPAND_IGNORE_SIZE
