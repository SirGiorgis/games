class_name PixelUI
extends RefCounted

static func menu_bg() -> ImageTexture:
	var img := Pix.image(320, 180, Color(0.06, 0.03, 0.08))
	Pix.dither_fill(img, 0, 0, 320, 180, Color(0.06, 0.03, 0.08), Color(0.04, 0.02, 0.06))
	for i in 30:
		Pix.put(img, (i * 37) % 320, (i * 13) % 90, Color(0.7, 0.15, 0.2, 0.5))
	Pix.rect(img, 0, 0, 320, 3, Color(0.85, 0.2, 0.28))
	Pix.rect(img, 0, 177, 320, 3, Color(0.85, 0.2, 0.28))
	return Pix.tex(img)


static func full_bg(parent: Control) -> TextureRect:
	var t := TextureRect.new()
	t.texture = menu_bg()
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


static func panel(w: int, h: int, fill: Color = Color(0.08, 0.05, 0.1), border: Color = Color(0.9, 0.75, 0.3)) -> ImageTexture:
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.rect(img, 0, 0, w, h, fill)
	Pix.rect(img, 1, 1, w - 2, h - 2, fill.lightened(0.04))
	Pix.hline(img, 0, 0, w, border)
	Pix.hline(img, 0, h - 1, w, border.darkened(0.3))
	Pix.vline(img, 0, 0, h, border)
	Pix.vline(img, w - 1, 0, h, border.darkened(0.3))
	return Pix.tex(img)


static func bar(w: int, h: int, fill: Color, t: float) -> ImageTexture:
	var img := Pix.image(w, h, Color(0.05, 0.04, 0.05))
	Pix.rect(img, 0, 0, w, h, Color(0.05, 0.04, 0.05))
	var fw := int(clampf(t, 0.0, 1.0) * float(w - 2))
	if fw > 0:
		Pix.rect(img, 1, 1, fw, h - 2, fill)
	Pix.hline(img, 0, 0, w, Color(0.2, 0.18, 0.2))
	Pix.hline(img, 0, h - 1, w, Color(0.2, 0.18, 0.2))
	return Pix.tex(img)


static func label_at(parent: Node, text: String, pos: Vector2, scale: int, color: Color, wrap: int = 0, center_w: int = 0) -> PixelLabel:
	var l := PixelLabel.new()
	l.set_pix(text, scale, color, wrap)
	l.position = pos
	if center_w > 0:
		l.set_centered(center_w)
	parent.add_child(l)
	return l
