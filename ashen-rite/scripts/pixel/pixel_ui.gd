class_name PixelUI
extends RefCounted

const W := 320
const H := 180
const GOLD := Color(0.92, 0.72, 0.28)
const RED := Color(0.88, 0.14, 0.22)
const INK := Color(0.04, 0.03, 0.06)
const PANEL := Color(0.08, 0.05, 0.1, 0.92)


static func menu_bg() -> ImageTexture:
	var img := Pix.image(W, H, Color(0.66, 0.80, 0.88))
	for y in H:
		var t: float = float(y) / float(H)
		var c: Color = Color(0.62, 0.80, 0.90).lerp(Color(0.42, 0.58, 0.28), clampf((t - 0.45) * 2.2, 0.0, 1.0))
		if t < 0.48:
			c = Color(0.66, 0.82, 0.90).lerp(Color(0.78, 0.88, 0.92), t / 0.48)
		Pix.hline(img, 0, y, W, c)
	# far mountain silhouette
	for y in 40:
		var w: int = int(float(y) / 40.0 * 70.0)
		Pix.hline(img, 200 - w, 28 + y, w * 2, Color(0.48, 0.56, 0.50, 0.85))
	Pix.disc(img, 48, 18, 9, Color(0.98, 0.92, 0.55))
	Pix.disc(img, 90, 16, 6, Color(0.96, 0.97, 0.98, 0.85))
	Pix.disc(img, 98, 17, 5, Color(0.94, 0.96, 0.98, 0.8))
	Pix.disc(img, 250, 14, 7, Color(0.96, 0.97, 0.99, 0.82))
	Pix.rect(img, 0, 0, W, 3, Color(0.18, 0.16, 0.12))
	Pix.rect(img, 0, H - 4, W, 4, Color(0.28, 0.42, 0.16))
	return Pix.tex(img)


static func full_bg(parent: Control) -> TextureRect:
	var t := TextureRect.new()
	t.texture = menu_bg()
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	var vig := TextureRect.new()
	vig.texture = vignette()
	vig.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.modulate.a = 0.62
	parent.add_child(vig)
	return t


static func vignette() -> ImageTexture:
	var img := Pix.image(80, 45, Color(0, 0, 0, 0))
	for y in 45:
		for x in 80:
			var nx: float = absf(float(x) / 79.0 * 2.0 - 1.0)
			var ny: float = absf(float(y) / 44.0 * 2.0 - 1.0)
			var e: float = pow(maxf(nx, ny), 2.6) * 0.55
			if e > 0.02:
				Pix.put(img, x, y, Color(0.02, 0.02, 0.04, e))
	return Pix.tex(img)


static func panel(w: int, h: int, fill: Color = PANEL, border: Color = GOLD) -> ImageTexture:
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.rect(img, 0, 0, w, h, fill)
	Pix.rect(img, 1, 1, w - 2, h - 2, fill.lightened(0.05))
	# double border arcade frame
	Pix.hline(img, 0, 0, w, border)
	Pix.hline(img, 0, 1, w, border.lightened(0.15))
	Pix.hline(img, 0, h - 1, w, border.darkened(0.35))
	Pix.hline(img, 0, h - 2, w, border.darkened(0.15))
	Pix.vline(img, 0, 0, h, border)
	Pix.vline(img, 1, 0, h, border.lightened(0.12))
	Pix.vline(img, w - 1, 0, h, border.darkened(0.35))
	Pix.vline(img, w - 2, 0, h, border.darkened(0.12))
	# corner studs
	Pix.rect(img, 0, 0, 3, 3, border.lightened(0.2))
	Pix.rect(img, w - 3, 0, 3, 3, border.lightened(0.2))
	Pix.rect(img, 0, h - 3, 3, 3, border.darkened(0.2))
	Pix.rect(img, w - 3, h - 3, 3, 3, border.darkened(0.2))
	return Pix.tex(img)


static func title_banner(text_w: int = 200) -> ImageTexture:
	var w: int = text_w + 24
	var h: int = 18
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.rect(img, 0, 4, w, h - 8, Color(0.12, 0.04, 0.08, 0.95))
	Pix.hline(img, 0, 3, w, RED)
	Pix.hline(img, 0, h - 4, w, RED.darkened(0.2))
	Pix.hline(img, 4, 5, w - 8, GOLD.darkened(0.1))
	Pix.hline(img, 4, h - 6, w - 8, GOLD.darkened(0.25))
	# chevrons
	for i in 4:
		Pix.put(img, 2 + i, 8 + i, GOLD)
		Pix.put(img, w - 3 - i, 8 + i, GOLD)
	return Pix.tex(img)


static func menu_row(w: int, selected: bool) -> ImageTexture:
	var h: int = 10
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	if selected:
		Pix.rect(img, 0, 0, w, h, Color(0.28, 0.08, 0.12, 0.96))
		Pix.rect(img, 1, 1, w - 2, h - 2, Color(0.34, 0.12, 0.14, 0.9))
		Pix.hline(img, 0, 0, w, GOLD)
		Pix.hline(img, 0, 1, w, GOLD.lightened(0.18))
		Pix.hline(img, 0, h - 1, w, GOLD.darkened(0.3))
		Pix.vline(img, 0, 0, h, Color(1, 0.88, 0.4, 0.75))
		Pix.vline(img, w - 1, 0, h, Color(1, 0.88, 0.4, 0.75))
		for i in 3:
			Pix.put(img, 3 + i, 5 - i, GOLD)
			Pix.put(img, 3 + i, 5 + i, GOLD)
			Pix.put(img, w - 4 - i, 5 - i, GOLD)
			Pix.put(img, w - 4 - i, 5 + i, GOLD)
	else:
		Pix.rect(img, 2, 2, w - 4, h - 4, Color(0.06, 0.04, 0.08, 0.5))
	return Pix.tex(img)


static func bar(w: int, h: int, fill: Color, t: float, label: String = "") -> ImageTexture:
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	# outer shell
	Pix.rect(img, 0, 0, w, h, Color(0.03, 0.02, 0.04))
	Pix.rect(img, 1, 1, w - 2, h - 2, Color(0.08, 0.06, 0.09))
	var fw: int = int(clampf(t, 0.0, 1.0) * float(w - 4))
	if fw > 0:
		Pix.rect(img, 2, 2, fw, h - 4, fill)
		# shine
		Pix.hline(img, 2, 2, fw, fill.lightened(0.22))
		# segment ticks
		var seg: int = 2
		while seg < w - 2:
			if seg < fw + 2:
				Pix.vline(img, seg, 3, h - 6, fill.darkened(0.18))
			seg += 8
	if t >= 0.99:
		Pix.hline(img, 0, 0, w, Color(1, 0.95, 0.6, 0.5))
	Pix.hline(img, 0, 0, w, Color(0.25, 0.2, 0.22))
	Pix.hline(img, 0, h - 1, w, Color(0.25, 0.2, 0.22))
	return Pix.tex(img)


static func meter_bar(w: int, h: int, fill: Color, t: float, ready: bool = false) -> ImageTexture:
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.round_rect(img, 0, 0, w, h, 2, Color(0.04, 0.03, 0.05))
	Pix.rect(img, 1, 1, w - 2, h - 2, Color(0.10, 0.08, 0.10))
	var fw: int = int(clampf(t, 0.0, 1.0) * float(w - 2))
	if fw > 0:
		var col: Color = fill.lightened(0.38) if ready else fill
		Pix.rect(img, 1, 1, fw, h - 2, col)
		Pix.hline(img, 1, 1, fw, col.lightened(0.28))
		Pix.hline(img, 1, h - 2, fw, col.darkened(0.22))
		var tick: int = 6
		while tick < fw:
			Pix.vline(img, 1 + tick, 2, h - 4, col.darkened(0.18))
			tick += 6
	Pix.hline(img, 0, 0, w, Color(0.38, 0.32, 0.28) if ready else Color(0.28, 0.24, 0.26))
	Pix.hline(img, 0, h - 1, w, Color(0.12, 0.10, 0.12))
	if ready:
		for x in range(0, w, 2):
			Pix.put(img, x, 0, Color(1, 0.96, 0.72, 0.55))
	return Pix.tex(img)


static func name_plate(w: int, h: int, accent: Color) -> ImageTexture:
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.rect(img, 0, 0, w, h, Color(0.07, 0.05, 0.09, 0.94))
	Pix.rect(img, 0, 0, 6, h, accent)
	Pix.hline(img, 0, 0, w, accent.lightened(0.15))
	Pix.hline(img, 0, h - 1, w, accent.darkened(0.35))
	return Pix.tex(img)


static func vs_emblem() -> ImageTexture:
	var img := Pix.image(48, 32, Color(0, 0, 0, 0))
	Pix.disc(img, 24, 16, 15, Color(0.18, 0.06, 0.10, 0.96))
	Pix.disc(img, 24, 16, 13, GOLD.darkened(0.15))
	Pix.disc(img, 24, 16, 11, Color(0.08, 0.04, 0.07))
	Pix.hline(img, 10, 14, 28, GOLD)
	Pix.hline(img, 10, 15, 28, Color(1, 0.95, 0.7))
	Pix.hline(img, 10, 17, 28, RED)
	Pix.hline(img, 10, 18, 28, RED.darkened(0.25))
	return Pix.tex(img)


static func char_card(w: int, h: int, accent: Color, p1: bool, p2: bool) -> ImageTexture:
	var border: Color = GOLD if p1 else (Color(0.35, 0.75, 1.0) if p2 else Color(0.28, 0.24, 0.3))
	var fill: Color = Color(0.18, 0.10, 0.08) if p1 else (Color(0.08, 0.13, 0.20) if p2 else Color(0.07, 0.05, 0.09))
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.rect(img, 0, 0, w, h, fill)
	Pix.rect(img, 2, 2, w - 4, h - 4, fill.lightened(0.06))
	Pix.hline(img, 0, 0, w, border)
	Pix.hline(img, 0, 1, w, border.lightened(0.18) if (p1 or p2) else border)
	Pix.hline(img, 0, h - 1, w, border.darkened(0.3))
	Pix.vline(img, 0, 0, h, border)
	Pix.vline(img, w - 1, 0, h, border.darkened(0.25))
	Pix.rect(img, 2, h - 5, w - 4, 3, accent.darkened(0.1))
	if p1:
		Pix.rect(img, 2, 2, 6, 6, GOLD)
		Pix.put(img, 4, 4, Color(0.08, 0.05, 0.04))
	if p2:
		Pix.rect(img, w - 8, 2, 6, 6, Color(0.4, 0.8, 1.0))
		Pix.put(img, w - 6, 4, Color(0.05, 0.08, 0.12))
	return Pix.tex(img)


static func portrait_frame(w: int, h: int, accent: Color) -> ImageTexture:
	return panel(w, h, Color(0.05, 0.03, 0.07, 0.95), accent)


static func round_gem(on: bool) -> ImageTexture:
	var img := Pix.image(10, 10, Color(0, 0, 0, 0))
	var rim: Color = GOLD if on else Color(0.22, 0.20, 0.20)
	var fill: Color = Color(1.0, 0.86, 0.28) if on else Color(0.12, 0.12, 0.13)
	Pix.disc(img, 5, 5, 4, rim)
	Pix.disc(img, 5, 5, 3, fill)
	if on:
		Pix.put(img, 4, 3, Color(1, 0.97, 0.78))
		Pix.put(img, 5, 4, Color(1, 0.95, 0.6))
	return Pix.tex(img)


static func timer_box() -> ImageTexture:
	var img := Pix.image(26, 26, Color(0, 0, 0, 0))
	Pix.disc(img, 13, 13, 13, Color(0.42, 0.28, 0.08))
	Pix.disc(img, 13, 13, 12, Color(0.96, 0.80, 0.22))
	Pix.disc(img, 13, 13, 11, Color(0.55, 0.36, 0.10))
	Pix.disc(img, 13, 13, 10, Color(0.08, 0.06, 0.06))
	Pix.disc(img, 13, 13, 8, Color(0.16, 0.13, 0.13))
	Pix.disc(img, 13, 13, 7, Color(0.07, 0.06, 0.06))
	Pix.put(img, 8, 7, Color(1, 0.95, 0.7, 0.55))
	Pix.put(img, 9, 6, Color(1, 0.96, 0.75, 0.4))
	return Pix.tex(img)


static func hud_top() -> ImageTexture:
	var img := Pix.image(W, 18, Color(0, 0, 0, 0))
	return Pix.tex(img)


static func tiny_hp(w: int, h: int, fill: Color, t: float, from_right: bool = false, chip: float = -1.0) -> ImageTexture:
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.round_rect(img, 0, 0, w, h, 3, Color(0.02, 0.02, 0.03))
	Pix.round_rect(img, 1, 1, w - 2, h - 2, 2, Color(0.14, 0.13, 0.13))
	Pix.hline(img, 1, 1, w - 2, Color(0.32, 0.30, 0.28))
	var inner: int = w - 4
	var ratio: float = clampf(t, 0.0, 1.0)
	var chip_r: float = clampf(chip if chip >= 0.0 else ratio, 0.0, 1.0)
	var fw: int = int(ratio * float(inner))
	var cw: int = int(chip_r * float(inner))
	if cw > fw:
		var cx0: int = 2 + (inner - cw if from_right else 0)
		Pix.rect(img, cx0, 2, cw, h - 4, Color(0.98, 0.90, 0.42))
		Pix.hline(img, cx0, 2, cw, Color(1.0, 0.97, 0.72))
	if fw > 0:
		var x0: int = 2 + (inner - fw if from_right else 0)
		Pix.rect(img, x0, 2, fw, h - 4, fill)
		Pix.hline(img, x0, 2, fw, fill.lightened(0.38))
		Pix.hline(img, x0, 3, fw, Color(1.0, 0.95, 0.55, 0.38))
		Pix.hline(img, x0, h - 3, fw, fill.darkened(0.24))
		var tick: int = 7
		while tick < fw:
			Pix.vline(img, x0 + tick, 3, h - 6, fill.darkened(0.18))
			tick += 7
	Pix.hline(img, 0, 0, w, Color(0.08, 0.07, 0.07))
	Pix.hline(img, 0, h - 1, w, Color(0.02, 0.02, 0.02))
	return Pix.tex(img)


static func name_pill(w: int, h: int, fill: Color, accent: Color = Color(0, 0, 0, 0)) -> ImageTexture:
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.rect(img, 1, 0, w - 2, h, fill)
	Pix.rect(img, 0, 1, w, h - 2, fill)
	Pix.hline(img, 1, 0, w - 2, fill.lightened(0.22))
	Pix.hline(img, 1, h - 1, w - 2, fill.darkened(0.18))
	if accent.a > 0.05:
		Pix.rect(img, 0, 1, 3, h - 2, accent)
		Pix.hline(img, 0, h - 2, w, accent.darkened(0.15))
	return Pix.tex(img)


static func fighter_portrait(tex: Texture2D, accent: Color) -> ImageTexture:
	var framed := Pix.image(22, 22, Color(0, 0, 0, 0))
	Pix.rect(framed, 0, 0, 22, 22, accent.darkened(0.35))
	Pix.rect(framed, 1, 1, 20, 20, Color(0.10, 0.08, 0.08))
	if tex:
		var src: Image = tex.get_image()
		if src.get_format() != Image.FORMAT_RGBA8:
			src.convert(Image.FORMAT_RGBA8)
		var rw: int = mini(20, src.get_width())
		var rh: int = mini(20, src.get_height())
		var sx: int = clampi((src.get_width() - rw) / 2, 0, src.get_width() - rw)
		var sy: int = clampi(2, 0, maxi(0, src.get_height() - rh))
		framed.blit_rect(src, Rect2i(sx, sy, rw, rh), Vector2i(1, 1))
	Pix.hline(framed, 0, 0, 22, accent)
	Pix.hline(framed, 0, 21, 22, accent.darkened(0.35))
	Pix.vline(framed, 0, 0, 22, accent)
	Pix.vline(framed, 21, 0, 22, accent.darkened(0.25))
	Pix.put(framed, 1, 1, Color(1, 1, 1, 0.25))
	return Pix.tex(framed)


static func stage_strip() -> ImageTexture:
	var img := Pix.image(120, 18, Color(0, 0, 0, 0))
	for y in 18:
		var t: float = float(y) / 17.0
		Pix.hline(img, 0, y, 120, Color(0.38, 0.58, 0.22).lerp(Color(0.22, 0.40, 0.14), t))
	Pix.hline(img, 0, 0, 120, Color(0.18, 0.28, 0.10))
	for i in 10:
		var x: int = 6 + i * 12
		Pix.put(img, x, 3 + (i % 3), Color(0.86, 0.28, 0.32, 0.7))
		Pix.put(img, x + 4, 8, Color(0.95, 0.82, 0.28, 0.55))
	return Pix.tex(img)


static func footer_hint() -> ImageTexture:
	var img := Pix.image(W, 8, Color(0, 0, 0, 0))
	Pix.rect(img, 0, 0, W, 8, Color(0.04, 0.03, 0.05, 0.85))
	Pix.hline(img, 0, 0, W, Color(0.35, 0.28, 0.2, 0.6))
	return Pix.tex(img)


static func modal_dim() -> Color:
	return Color(0.02, 0.01, 0.04, 0.78)


static func label_at(parent: Node, text: String, pos: Vector2, scale: int, color: Color, wrap: int = 0, center_w: int = 0) -> PixelLabel:
	var l := PixelLabel.new()
	l.set_pix(text, scale, color, wrap)
	l.position = pos
	if center_w > 0:
		l.set_centered(center_w)
	parent.add_child(l)
	return l


static func add_panel(parent: Control, pos: Vector2, size: Vector2, border: Color = GOLD) -> TextureRect:
	var t := TextureRect.new()
	t.texture = panel(int(size.x / 4), int(size.y / 4), PANEL, border)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.position = pos
	t.size = size
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


static func add_title(parent: Control, text: String, y: float, color: Color = RED) -> PixelLabel:
	var banner := TextureRect.new()
	banner.texture = title_banner(220)
	banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	banner.position = Vector2(0, y - 8)
	banner.size = Vector2(1280, 72)
	banner.stretch_mode = TextureRect.STRETCH_SCALE
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(banner)
	var lbl := label_at(parent, text, Vector2(0, y), 5, color, 0, 1280)
	return lbl


static func add_footer(parent: Control, text: String) -> void:
	var bar := TextureRect.new()
	bar.texture = footer_hint()
	bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bar.position = Vector2(0, 688)
	bar.size = Vector2(1280, 32)
	bar.stretch_mode = TextureRect.STRETCH_SCALE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	label_at(parent, text, Vector2(0, 692), 2, Color(0.72, 0.68, 0.62), 0, 1280)


static func round_banner(w: int = 140) -> ImageTexture:
	var h: int = 30
	var img := Pix.image(w, h, Color(0, 0, 0, 0))
	Pix.rect(img, 0, 5, w, h - 10, Color(0.08, 0.02, 0.07, 0.97))
	Pix.hline(img, 0, 3, w, RED)
	Pix.hline(img, 0, 4, w, RED.lightened(0.12))
	Pix.hline(img, 0, h - 4, w, RED.darkened(0.25))
	Pix.hline(img, 8, 7, w - 16, GOLD)
	Pix.hline(img, 8, h - 8, w - 16, GOLD.darkened(0.28))
	for i in 6:
		Pix.put(img, 3 + i, 13 + i, GOLD)
		Pix.put(img, w - 4 - i, 13 + i, GOLD)
		Pix.put(img, 3 + i, 13 - i, GOLD)
		Pix.put(img, w - 4 - i, 13 - i, GOLD)
	return Pix.tex(img)


static func add_menu_row(parent: Control, y: float, w_px: int = 520) -> Dictionary:
	var art_w: int = int(w_px / 4)
	var row := TextureRect.new()
	row.texture = menu_row(art_w, false)
	row.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.position = Vector2(640 - w_px * 0.5, y)
	row.size = Vector2(w_px, 40)
	row.stretch_mode = TextureRect.STRETCH_SCALE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	var lbl := PixelLabel.new()
	lbl.position = Vector2(640 - w_px * 0.5 + 16, y + 8)
	parent.add_child(lbl)
	return {"row": row, "label": lbl, "w": w_px}


static func set_menu_row(entry: Dictionary, text: String, selected: bool, scale: int = 3) -> void:
	var row: TextureRect = entry["row"]
	var lbl: PixelLabel = entry["label"]
	var w_px: int = entry["w"]
	row.texture = menu_row(int(w_px / 4), selected)
	var txt: String = (">  " + text + "  <") if selected else text
	lbl.set_pix(txt, scale, Color(1, 0.88, 0.38) if selected else Color(0.78, 0.74, 0.7))
