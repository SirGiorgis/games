extends SceneTree
## Headless proof of the four unique supers.


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
	_blit(field, title, 640 - title.get_width() / 2, 18)
	var sub := PixelFont.make("O  WHEN SUPER IS FULL", Color(0.92, 0.90, 0.84), 2).get_image()
	_blit(field, sub, 640 - sub.get_width() / 2, 62)

	var chris := _def("chris_xrisakis")
	var mako := _def("mako")
	var giorgis := _def("hoodrich_stacks")
	var fogas := _def("fogas")

	_panel(field, 16, 110, 300, 560)
	_panel(field, 332, 110, 300, 560)
	_panel(field, 648, 110, 300, 560)
	_panel(field, 964, 110, 300, 560)

	_stamp_fighter(field, chris, "ultimate", 8, 166, 400, false)
	var car: Image = Pix.car()
	car.resize(car.get_width() * 3, car.get_height() * 3, Image.INTERPOLATE_NEAREST)
	field.blend_rect(car, Rect2i(0, 0, car.get_width(), car.get_height()), Vector2i(188, 368))
	field.blend_rect(car, Rect2i(0, 0, car.get_width(), car.get_height()), Vector2i(238, 348))
	_label(field, "CHRIS", Color(0.96, 0.22, 0.28), 166, 428)
	_label(field, chris.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 166, 456)
	_wrap(field, "Original open-wheel pack. Rosso livery, CX mark. No team badges.", Color(0.88, 0.86, 0.80), 36, 500, 28)

	_stamp_fighter(field, mako, "ultimate", 4, 482, 400, false)
	_label(field, "MAKO", Color(0.88, 0.62, 0.38), 482, 428)
	_label(field, mako.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 482, 456)
	_wrap(field, "Weaving hook storm. Armor on the way in.", Color(0.88, 0.86, 0.80), 352, 500, 28)

	_stamp_fighter(field, giorgis, "ultimate", 8, 798, 400, false)
	_label(field, "GIORGIS", Color(0.55, 0.82, 0.95), 798, 428)
	_label(field, giorgis.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 798, 456)
	_wrap(field, "Drinks. Heals 28% HP. ATK x1.38 for 10s.", Color(0.88, 0.86, 0.80), 668, 500, 28)

	_stamp_fighter(field, fogas, "ultimate", 8, 1114, 400, false)
	var gas: Image = Pix.gas()
	gas.resize(gas.get_width() * 4, gas.get_height() * 4, Image.INTERPOLATE_NEAREST)
	field.blend_rect(gas, Rect2i(0, 0, gas.get_width(), gas.get_height()), Vector2i(1048, 360))
	field.blend_rect(gas, Rect2i(0, 0, gas.get_width(), gas.get_height()), Vector2i(1120, 380))
	_label(field, "FOGAS", Color(0.92, 0.86, 0.70), 1114, 428)
	_label(field, fogas.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 1114, 456)
	_wrap(field, "Gas blast. Instant stun hit, then lingering poison.", Color(0.88, 0.86, 0.80), 984, 500, 28)

	var foot := PixelFont.make("GRID STRIKE  DEMPSEY ROLL  STRAIGHT VODKA  GUT BLAST", Color(0.85, 0.78, 0.62), 2).get_image()
	_blit(field, foot, 640 - foot.get_width() / 2, 688)

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
