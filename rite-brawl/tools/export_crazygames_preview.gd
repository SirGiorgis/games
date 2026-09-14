extends SceneTree
## Headless proof of CrazyGames display names and arcade continue copy.


func _init() -> void:
	PixelFighterBake.clear_cache()
	_roster()
	_continue()
	print("crazygames preview -> res://.godot/crazygames_preview")
	quit()


func _roster() -> void:
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.08, 0.06, 0.09))
	var title: Image = PixelFont.make("RITE BRAWL", Color(0.95, 0.18, 0.28), 4).get_image()
	_blit(field, title, 640 - title.get_width() / 2, 24)
	var sub: Image = PixelFont.make("CRAZYGAMES NAMES", Color(0.95, 0.82, 0.35), 2).get_image()
	_blit(field, sub, 640 - sub.get_width() / 2, 72)
	var ids := ["chris_xrisakis", "hoodrich_stacks", "mako", "fogas", "giannis", "vag", "spyros"]
	var xs: Array[int] = [90, 270, 450, 630, 810, 990, 1170]
	for i in ids.size():
		var def := _def(ids[i])
		_stamp_fighter(field, def, "idle", 0, xs[i], 430, false)
		var nm: Image = PixelFont.make(def.callsign(), def.accent, 2).get_image()
		_blit(field, nm, xs[i] - nm.get_width() / 2, 456)
		var ult: Image = PixelFont.make(def.ultimate_name.to_upper(), Color(0.98, 0.86, 0.32), 1).get_image()
		_blit(field, ult, xs[i] - ult.get_width() / 2, 488)
	var stage: Image = PixelFont.make(ArenaWorld.display_name("grass_field"), Color(1, 0.88, 0.42), 3).get_image()
	_blit(field, stage, 640 - stage.get_width() / 2, 560)
	var note: Image = PixelFont.make("TASOS  SHOW OUT   DEFAULT STAGE RITE FIELD", Color(0.82, 0.78, 0.72), 2).get_image()
	_blit(field, note, 640 - note.get_width() / 2, 620)
	_save(field, "roster")


func _continue() -> void:
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.07, 0.05, 0.08))
	var panel := Image.create(840, 560, false, Image.FORMAT_RGBA8)
	panel.fill(Color(0.08, 0.05, 0.10, 0.92))
	field.blend_rect(panel, Rect2i(0, 0, 840, 560), Vector2i(220, 72))
	var title: Image = PixelFont.make("CONTINUE?", Color(0.88, 0.22, 0.28), 5).get_image()
	_blit(field, title, 640 - title.get_width() / 2, 120)
	var watch: Image = PixelFont.make(">  WATCH AD TO CONTINUE  <", Color(1, 0.88, 0.38), 2).get_image()
	_blit(field, watch, 640 - watch.get_width() / 2, 420)
	var skip: Image = PixelFont.make("GIVE UP", Color(0.78, 0.74, 0.7), 2).get_image()
	_blit(field, skip, 640 - skip.get_width() / 2, 478)
	var hint: Image = PixelFont.make("OPTIONAL  SAME SIZE SKIP  VIDEO AD", Color(0.72, 0.68, 0.64), 1).get_image()
	_blit(field, hint, 640 - hint.get_width() / 2, 560)
	_save(field, "continue")


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


func _save(field: Image, name: String) -> void:
	var out := "res://.godot/crazygames_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/%s.png" % [out, name]))


func _blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))
