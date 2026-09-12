extends SceneTree
## Headless Tiny Fight-style preview: arena + roster + HUD mock.


func _init() -> void:
	PixelFighterBake.clear_cache()
	var arena: Image = PixelArenaBake.texture("grass_field").get_image()
	arena.convert(Image.FORMAT_RGBA8)
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.66, 0.80, 0.88))
	arena.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	field.blit_rect(arena, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)

	var chris := _def("chris_xrisakis")
	var giorgis := _def("hoodrich_stacks")
	var mako := _def("mako")
	var fogas := _def("fogas")
	var giannis := _def("giannis")
	var vag := _def("vag")
	var spyros := _def("spyros")
	_stamp_fighter(field, chris, "idle", 0, 80, 620, false)
	_stamp_fighter(field, mako, "idle", 0, 260, 620, false)
	_stamp_fighter(field, vag, "ultimate", 8, 440, 620, false)
	_stamp_fighter(field, fogas, "idle", 0, 620, 620, false)
	_stamp_fighter(field, giannis, "idle", 0, 800, 620, false)
	_stamp_fighter(field, spyros, "ultimate", 10, 980, 620, false)
	_stamp_fighter(field, giorgis, "idle", 0, 1160, 620, true)

	var car: Image = Pix.car()
	car.resize(car.get_width() * 4, car.get_height() * 4, Image.INTERPOLATE_NEAREST)
	field.blend_rect(car, Rect2i(0, 0, car.get_width(), car.get_height()), Vector2i(140, 560))
	field.blend_rect(car, Rect2i(0, 0, car.get_width(), car.get_height()), Vector2i(200, 548))

	var gas: Image = Pix.gas()
	gas.resize(gas.get_width() * 5, gas.get_height() * 5, Image.INTERPOLATE_NEAREST)
	field.blend_rect(gas, Rect2i(0, 0, gas.get_width(), gas.get_height()), Vector2i(700, 530))
	field.blend_rect(gas, Rect2i(0, 0, gas.get_width(), gas.get_height()), Vector2i(760, 548))

	var boll: Image = Pix.cotton()
	boll.resize(boll.get_width() * 4, boll.get_height() * 4, Image.INTERPOLATE_NEAREST)
	field.blend_rect(boll, Rect2i(0, 0, boll.get_width(), boll.get_height()), Vector2i(430, 588))
	field.blend_rect(boll, Rect2i(0, 0, boll.get_width(), boll.get_height()), Vector2i(500, 596))
	field.blend_rect(boll, Rect2i(0, 0, boll.get_width(), boll.get_height()), Vector2i(570, 584))
	field.blend_rect(boll, Rect2i(0, 0, boll.get_width(), boll.get_height()), Vector2i(640, 592))

	_hud(field, chris, giorgis)
	var out := "res://.godot/tiny_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/fight.png" % out))

	_export_strips(chris, "chris_xrisakis")
	_export_strips(giorgis, "hoodrich_stacks")
	_export_strips(fogas, "fogas")
	_export_strips(giannis, "giannis")
	_export_strips(vag, "vag")
	_export_strips(spyros, "spyros")
	print("tiny preview -> %s" % out)
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


func _hud(dst: Image, chris: CharacterDef, giorgis: CharacterDef) -> void:
	var veil := Image.create(1280, 108, false, Image.FORMAT_RGBA8)
	veil.fill(Color(0.02, 0.03, 0.04, 0.42))
	dst.blend_rect(veil, Rect2i(0, 0, 1280, 108), Vector2i.ZERO)
	var hair := Image.create(1280, 2, false, Image.FORMAT_RGBA8)
	hair.fill(Color(0.92, 0.74, 0.28, 0.55))
	dst.blend_rect(hair, Rect2i(0, 0, 1280, 2), Vector2i(0, 108))

	var idle_c: Texture2D = PixelFighterBake.bake(chris)["idle"][0]
	var idle_g: Texture2D = PixelFighterBake.bake(giorgis)["idle"][0]
	var port1: Image = PixelUI.fighter_portrait(idle_c, chris.accent).get_image()
	var port2: Image = PixelUI.fighter_portrait(idle_g, giorgis.accent).get_image()
	port1.resize(port1.get_width() * 4, port1.get_height() * 4, Image.INTERPOLATE_NEAREST)
	port2.resize(port2.get_width() * 4, port2.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(port1, Rect2i(0, 0, port1.get_width(), port1.get_height()), Vector2i(16, 8))
	dst.blend_rect(port2, Rect2i(0, 0, port2.get_width(), port2.get_height()), Vector2i(1280 - 16 - port2.get_width(), 8))

	var n1: Image = PixelFont.make("CHRIS", Color(0.98, 0.98, 0.95), 2).get_image()
	var n2: Image = PixelFont.make("GIORGIS", Color(0.98, 0.98, 0.95), 2).get_image()
	var p1w: int = 40
	var p2w: int = 52
	var pill1: Image = PixelUI.name_pill(p1w, 11, Color(0.05, 0.05, 0.06), chris.accent).get_image()
	var pill2: Image = PixelUI.name_pill(p2w, 11, Color(0.05, 0.05, 0.06), giorgis.accent).get_image()
	pill1.resize(pill1.get_width() * 4, pill1.get_height() * 4, Image.INTERPOLATE_NEAREST)
	pill2.resize(pill2.get_width() * 4, pill2.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(pill1, Rect2i(0, 0, pill1.get_width(), pill1.get_height()), Vector2i(112, 10))
	dst.blend_rect(pill2, Rect2i(0, 0, pill2.get_width(), pill2.get_height()), Vector2i(1280 - 112 - p2w * 4, 10))
	dst.blend_rect(n1, Rect2i(0, 0, n1.get_width(), n1.get_height()), Vector2i(124, 16))
	dst.blend_rect(n2, Rect2i(0, 0, n2.get_width(), n2.get_height()), Vector2i(1280 - 124 - n2.get_width(), 16))

	var hp1: Image = PixelUI.tiny_hp(138, 11, Color(0.30, 0.84, 0.24), 1.0).get_image()
	var hp2: Image = PixelUI.tiny_hp(138, 11, Color(0.90, 0.18, 0.22), 0.62, true, 0.86).get_image()
	hp1.resize(hp1.get_width() * 4, hp1.get_height() * 4, Image.INTERPOLATE_NEAREST)
	hp2.resize(hp2.get_width() * 4, hp2.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(hp1, Rect2i(0, 0, hp1.get_width(), hp1.get_height()), Vector2i(16, 60))
	dst.blend_rect(hp2, Rect2i(0, 0, hp2.get_width(), hp2.get_height()), Vector2i(712, 60))

	var tbox: Image = PixelUI.timer_box().get_image()
	tbox.resize(tbox.get_width() * 4, tbox.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(tbox, Rect2i(0, 0, tbox.get_width(), tbox.get_height()), Vector2i(588, 4))
	var num: Image = PixelFont.make("99", Color(1, 1, 1), 3).get_image()
	dst.blend_rect(num, Rect2i(0, 0, num.get_width(), num.get_height()), Vector2i(640 - num.get_width() / 2, 34))
	var vs: Image = PixelFont.make("VS", Color(0.95, 0.78, 0.32), 1).get_image()
	dst.blend_rect(vs, Rect2i(0, 0, vs.get_width(), vs.get_height()), Vector2i(640 - vs.get_width() / 2, 88))

	var gem: Image = PixelUI.round_gem(true).get_image()
	gem.resize(gem.get_width() * 3, gem.get_height() * 3, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(gem, Rect2i(0, 0, gem.get_width(), gem.get_height()), Vector2i(292, 14))
	var gem2: Image = PixelUI.round_gem(false).get_image()
	gem2.resize(gem2.get_width() * 3, gem2.get_height() * 3, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(gem2, Rect2i(0, 0, gem2.get_width(), gem2.get_height()), Vector2i(324, 14))

	var combo: Image = PixelFont.make("5 HIT  312  60%", Color(1, 0.86, 0.28), 4).get_image()
	dst.blend_rect(combo, Rect2i(0, 0, combo.get_width(), combo.get_height()), Vector2i(640 - combo.get_width() / 2, 168))
	var rank: Image = PixelFont.make("GREAT", Color(1.0, 0.72, 0.28), 2).get_image()
	dst.blend_rect(rank, Rect2i(0, 0, rank.get_width(), rank.get_height()), Vector2i(640 - rank.get_width() / 2, 214))
	var hpnum: Image = PixelFont.make("880", Color(0.98, 0.98, 0.94), 1).get_image()
	dst.blend_rect(hpnum, Rect2i(0, 0, hpnum.get_width(), hpnum.get_height()), Vector2i(24, 64))
	var rage: Image = PixelFont.make("RAGE", Color(1.0, 0.35, 0.28), 1).get_image()
	dst.blend_rect(rage, Rect2i(0, 0, rage.get_width(), rage.get_height()), Vector2i(990, 84))
	var poison: Image = PixelFont.make("POISON", Color(0.55, 0.92, 0.32), 1).get_image()
	dst.blend_rect(poison, Rect2i(0, 0, poison.get_width(), poison.get_height()), Vector2i(860, 84))
	var mx: Image = PixelFont.make("MAX", Color(0.45, 0.9, 1.0), 2).get_image()
	dst.blend_rect(mx, Rect2i(0, 0, mx.get_width(), mx.get_height()), Vector2i(380, 668))

	var sp1: Image = PixelUI.meter_bar(56, 6, Color(0.88, 0.34, 0.64), 0.7).get_image()
	sp1.resize(sp1.get_width() * 4, sp1.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(sp1, Rect2i(0, 0, sp1.get_width(), sp1.get_height()), Vector2i(16, 116))
	var ult1: Image = PixelUI.meter_bar(88, 7, Color(0.25, 0.74, 0.96), 0.45).get_image()
	ult1.resize(ult1.get_width() * 4, ult1.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(ult1, Rect2i(0, 0, ult1.get_width(), ult1.get_height()), Vector2i(16, 668))


func _export_strips(def: CharacterDef, id: String) -> void:
	var frames: Dictionary = PixelFighterBake.bake(def)
	var dir := "res://.godot/%s_preview" % id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for key in ["idle", "walk", "run", "light", "heavy", "jump", "ultimate"]:
		if not frames.has(key):
			continue
		var arr: Array = frames[key]
		if arr.is_empty():
			continue
		var fw: int = (arr[0] as ImageTexture).get_width()
		var fh: int = (arr[0] as ImageTexture).get_height()
		var strip := Image.create(fw * arr.size(), fh, false, Image.FORMAT_RGBA8)
		strip.fill(Color(0, 0, 0, 0))
		for i in arr.size():
			var fr: Image = (arr[i] as ImageTexture).get_image()
			strip.blit_rect(fr, Rect2i(0, 0, fw, fh), Vector2i(fw * i, 0))
		strip.save_png(ProjectSettings.globalize_path("%s/%s_strip.png" % [dir, key]))
		var solo: Image = (arr[0] as ImageTexture).get_image()
		solo.resize(solo.get_width() * 4, solo.get_height() * 4, Image.INTERPOLATE_NEAREST)
		solo.save_png(ProjectSettings.globalize_path("%s/%s.png" % [dir, key]))
