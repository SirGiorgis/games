extends SceneTree
## Headless proof of the unique supers.


func _init() -> void:
	PixelFighterBake.clear_cache()
	var arena: Image = PixelArenaBake.texture("grass_field").get_image()
	arena.convert(Image.FORMAT_RGBA8)
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.10, 0.08, 0.12))
	arena.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	field.blit_rect(arena, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)
	var veil := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	veil.fill(Color(0.04, 0.03, 0.05, 0.28))
	field.blend_rect(veil, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)

	var title := PixelFont.make("UNIQUE SUPERS", Color(0.95, 0.82, 0.35), 4).get_image()
	_blit(field, title, 640 - title.get_width() / 2, 8)
	var sub := PixelFont.make("O  WHEN SUPER IS FULL", Color(0.92, 0.90, 0.84), 2).get_image()
	_blit(field, sub, 640 - sub.get_width() / 2, 46)

	var chris := _def("chris_xrisakis")
	var mako := _def("mako")
	var giorgis := _def("hoodrich_stacks")
	var fogas := _def("fogas")
	var giannis := _def("giannis")
	var vag := _def("vag")
	var spyros := _def("spyros")

	# 4 x 2 panels
	var pw := 300
	var ph := 300
	var xs: Array[int] = [16, 328, 640, 952]
	var ys: Array[int] = [72, 392]
	for yi in ys.size():
		for xi in xs.size():
			if yi == 1 and xi == 3:
				continue
			_panel(field, xs[xi], ys[yi], pw, ph)

	_stamp_fighter(field, chris, "ultimate", 8, 166, 268, false)
	var car: Image = Pix.car()
	car.resize(car.get_width() * 3, car.get_height() * 3, Image.INTERPOLATE_NEAREST)
	field.blend_rect(car, Rect2i(0, 0, car.get_width(), car.get_height()), Vector2i(188, 236))
	_label(field, "CHRIS", Color(0.96, 0.22, 0.28), 166, 280)
	_label(field, chris.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 166, 304)
	_wrap(field, "Original open-wheel pack. CX mark.", Color(0.88, 0.86, 0.80), 28, 328, 28)

	_stamp_fighter(field, mako, "ultimate", 4, 478, 268, false)
	_label(field, "MAKO", Color(0.88, 0.62, 0.38), 478, 280)
	_label(field, mako.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 478, 304)
	_wrap(field, "Weaving hook storm. Armor in.", Color(0.88, 0.86, 0.80), 340, 328, 28)

	_stamp_fighter(field, giorgis, "ultimate", 8, 790, 268, false)
	_label(field, "GIORGIS", Color(0.55, 0.82, 0.95), 790, 280)
	_label(field, giorgis.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 790, 304)
	_wrap(field, "Heals 28% HP. ATK x1.38 for 10s.", Color(0.88, 0.86, 0.80), 652, 328, 28)

	_stamp_fighter(field, fogas, "ultimate", 8, 1102, 268, false)
	var gas: Image = Pix.gas()
	gas.resize(gas.get_width() * 3, gas.get_height() * 3, Image.INTERPOLATE_NEAREST)
	field.blend_rect(gas, Rect2i(0, 0, gas.get_width(), gas.get_height()), Vector2i(1042, 220))
	_label(field, "FOGAS", Color(0.92, 0.86, 0.70), 1102, 280)
	_label(field, fogas.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 1102, 304)
	_wrap(field, "Stun blast, then poison cloud.", Color(0.88, 0.86, 0.80), 964, 328, 28)

	_stamp_fighter(field, giannis, "ultimate", 10, 166, 588, false)
	_label(field, "GIANNIS", Color(0.35, 0.82, 0.92), 166, 600)
	_label(field, giannis.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 166, 624)
	_wrap(field, "Rips the hoodie. Pushes all. ATK x1.42.", Color(0.88, 0.86, 0.80), 28, 648, 28)

	_stamp_fighter(field, vag, "ultimate", 8, 478, 588, false)
	var boll: Image = Pix.cotton()
	boll.resize(boll.get_width() * 4, boll.get_height() * 4, Image.INTERPOLATE_NEAREST)
	field.blend_rect(boll, Rect2i(0, 0, boll.get_width(), boll.get_height()), Vector2i(396, 548))
	field.blend_rect(boll, Rect2i(0, 0, boll.get_width(), boll.get_height()), Vector2i(464, 556))
	_label(field, "VAG", Color(0.92, 0.88, 0.78), 478, 600)
	_label(field, vag.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 478, 624)
	_wrap(field, "Cotton on the floor. Pick up to heal and chip.", Color(0.88, 0.86, 0.80), 340, 648, 28)

	_stamp_fighter(field, spyros, "ultimate", 10, 790, 588, false)
	_label(field, "SPYROS", Color(0.92, 0.78, 0.32), 790, 600)
	_label(field, spyros.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 790, 624)
	_wrap(field, "Bass drop. Stacks the chain. ATK x1.40.", Color(0.88, 0.86, 0.80), 652, 648, 28)

	var out := "res://.godot/super_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/supers.png" % out))
	print("super preview -> %s/supers.png" % out)
	quit()


func _def(id: String) -> CharacterDef:
	var f := FileAccess.open("res://data/characters/%s.json" % id, FileAccess.READ)
	return CharacterDef.new().from_dict(JSON.parse_string(f.get_as_text()))


func _stamp_fighter(dst: Image, def: CharacterDef, pose: String, frame: int, feet_x: int, feet_y: int, flip: bool) -> void:
	var frames: Dictionary = PixelFighterBake.bake(def)
	var arr: Array = frames.get(pose, frames["idle"])
	var tex: ImageTexture = arr[clampi(frame, 0, arr.size() - 1)]
	var src: Image = tex.get_image()
	var sc: float = float(PixelFighterBake.SCALE)
	src.resize(
		maxi(1, int(round(float(src.get_width()) * sc * def.width_scale))),
		maxi(1, int(round(float(src.get_height()) * sc * def.height_scale))),
		Image.INTERPOLATE_NEAREST
	)
	if flip:
		src.flip_x()
	var ox: int = feet_x - src.get_width() / 2
	var oy: int = feet_y - src.get_height()
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(ox, oy))


func _panel(dst: Image, x: int, y: int, w: int, h: int) -> void:
	var p := Image.create(w, h, false, Image.FORMAT_RGBA8)
	p.fill(Color(0.06, 0.06, 0.08, 0.62))
	dst.blend_rect(p, Rect2i(0, 0, w, h), Vector2i(x, y))


func _label(dst: Image, text: String, col: Color, cx: int, y: int) -> void:
	var img: Image = PixelFont.make(text, col, 2).get_image()
	_blit(dst, img, cx - img.get_width() / 2, y)


func _wrap(dst: Image, text: String, col: Color, x: int, y: int, wrap: int) -> void:
	var img: Image = PixelFont.make(text, col, 1, wrap).get_image()
	_blit(dst, img, x, y)


func _blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))
