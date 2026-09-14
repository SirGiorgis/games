extends SceneTree
## Headless proof of arcade juice: KO banner, combo rank, VS punch, letterbox.


func _init() -> void:
	PixelFighterBake.clear_cache()
	_fight_ko()
	_versus()
	_clutch()
	_splash()
	print("juice preview -> res://.godot/juice_preview")
	quit()


func _fight_ko() -> void:
	var arena: Image = PixelArenaBake.texture("grass_field").get_image()
	arena.convert(Image.FORMAT_RGBA8)
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.66, 0.80, 0.88))
	arena.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	field.blit_rect(arena, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)
	var veil := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	veil.fill(Color(1.0, 0.92, 0.75, 0.12))
	field.blend_rect(veil, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)

	var chris := _def("chris_xrisakis")
	var giorgis := _def("hoodrich_stacks")
	_stamp_fighter(field, chris, "ultimate", 8, 430, 620, false)
	_stamp_fighter(field, giorgis, "knockdown", 6, 860, 620, true)

	var top := Image.create(1280, 64, false, Image.FORMAT_RGBA8)
	top.fill(Color(0, 0, 0, 0.78))
	field.blend_rect(top, Rect2i(0, 0, 1280, 64), Vector2i(0, 0))
	field.blend_rect(top, Rect2i(0, 0, 1280, 64), Vector2i(0, 656))

	var combo: Image = PixelFont.make("8 HIT  640  22%", Color(1.0, 0.45, 0.22), 4).get_image()
	_blit(field, combo, 640 - combo.get_width() / 2, 168)
	var rank: Image = PixelFont.make("UNBELIEVABLE", Color(1.0, 0.45, 0.22), 2).get_image()
	_blit(field, rank, 640 - rank.get_width() / 2, 214)

	var banner: Image = PixelUI.round_banner(110).get_image()
	banner.resize(banner.get_width() * 4, banner.get_height() * 4, Image.INTERPOLATE_NEAREST)
	_blit(field, banner, 640 - banner.get_width() / 2, 264)
	var ko: Image = PixelFont.make("KO", Color(0.95, 0.78, 0.28), 6).get_image()
	_blit(field, ko, 640 - ko.get_width() / 2, 292)

	var out := "res://.godot/juice_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/ko.png" % out))


func _versus() -> void:
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.02, 0.02, 0.04))
	var chris := _def("chris_xrisakis")
	var spyros := _def("spyros")
	_stamp_fighter(field, chris, "walk", 2, 300, 520, false)
	_stamp_fighter(field, spyros, "walk", 2, 980, 520, true)
	var t1: Image = PixelFont.make(chris.callsign(), Color(1, 0.88, 0.4), 4).get_image()
	var t2: Image = PixelFont.make(spyros.callsign(), Color(0.55, 0.88, 1.0), 4).get_image()
	_blit(field, t1, 300 - t1.get_width() / 2, 140)
	_blit(field, t2, 980 - t2.get_width() / 2, 140)
	var vs: Image = PixelUI.vs_emblem().get_image()
	vs.resize(vs.get_width() * 4, vs.get_height() * 4, Image.INTERPOLATE_NEAREST)
	_blit(field, vs, 640 - vs.get_width() / 2, 280)
	var skip: Image = PixelFont.make("ENTER / CROSS SKIPS", Color(0.75, 0.72, 0.68), 1).get_image()
	_blit(field, skip, 640 - skip.get_width() / 2, 620)
	var moves: Image = PixelFont.make("L VERSE CUT   O TRAP DROP", Color(0.95, 0.82, 0.42), 2).get_image()
	_blit(field, moves, 640 - moves.get_width() / 2, 560)
	var out := "res://.godot/juice_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/versus.png" % out))


func _clutch() -> void:
	var arena: Image = PixelArenaBake.texture("grass_field").get_image()
	arena.convert(Image.FORMAT_RGBA8)
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.66, 0.80, 0.88))
	arena.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	field.blit_rect(arena, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)
	var red := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	red.fill(Color(0.42, 0.02, 0.05, 0.20))
	field.blend_rect(red, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)
	var chris := _def("chris_xrisakis")
	var mako := _def("mako")
	_stamp_fighter(field, chris, "block_hit", 2, 420, 620, false)
	_stamp_fighter(field, mako, "heavy", 4, 860, 620, true)
	var top := Image.create(1280, 64, false, Image.FORMAT_RGBA8)
	top.fill(Color(0, 0, 0, 0.78))
	field.blend_rect(top, Rect2i(0, 0, 1280, 64), Vector2i(0, 0))
	field.blend_rect(top, Rect2i(0, 0, 1280, 64), Vector2i(0, 656))
	var mx: Image = PixelFont.make("MAX", Color(0.45, 0.9, 1.0), 2).get_image()
	_blit(field, mx, 380, 668)
	var banner: Image = PixelUI.round_banner(140).get_image()
	banner.resize(banner.get_width() * 4, banner.get_height() * 4, Image.INTERPOLATE_NEAREST)
	_blit(field, banner, 640 - banner.get_width() / 2, 264)
	var tm: Image = PixelFont.make("TIME", Color(0.75, 0.82, 1.0), 6).get_image()
	_blit(field, tm, 640 - tm.get_width() / 2, 292)
	var out := "res://.godot/juice_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/clutch.png" % out))


func _splash() -> void:
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.07, 0.05, 0.08))
	var chris := _def("chris_xrisakis")
	var giorgis := _def("hoodrich_stacks")
	_stamp_fighter(field, chris, "walk", 2, 430, 520, false)
	_stamp_fighter(field, giorgis, "walk", 3, 850, 520, true)
	var title: Image = PixelFont.make("GIORGIS FIGHTING", Color(0.95, 0.18, 0.28), 5).get_image()
	_blit(field, title, 640 - title.get_width() / 2, 88)
	var sub: Image = PixelFont.make("ARCADE BRAWL", Color(0.92, 0.74, 0.32), 2).get_image()
	_blit(field, sub, 640 - sub.get_width() / 2, 164)
	var press: Image = PixelFont.make("PRESS ENTER / CROSS", Color(1, 0.92, 0.45), 3).get_image()
	_blit(field, press, 640 - press.get_width() / 2, 600)
	var out := "res://.godot/juice_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/splash.png" % out))


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


func _blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))
