extends SceneTree
## Headless Tiny Fight-style preview: arena + Chris vs Giorgis + HUD mock.


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
	_stamp_fighter(field, chris, "idle", 0, 500, 620, false)
	_stamp_fighter(field, giorgis, "idle", 0, 760, 620, true)
	_stamp_fighter(field, chris, "light", 5, 200, 620, false)
	_stamp_fighter(field, giorgis, "heavy", 7, 1080, 620, true)

	_hud(field)
	var out := "res://.godot/tiny_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/fight.png" % out))

	_export_strips(chris, "chris_xrisakis")
	_export_strips(giorgis, "hoodrich_stacks")
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
	var sc: int = PixelFighterBake.SCALE
	src.resize(src.get_width() * sc, src.get_height() * sc, Image.INTERPOLATE_NEAREST)
	if flip:
		src.flip_x()
	var ox: int = feet_x - src.get_width() / 2
	var oy: int = feet_y - src.get_height()
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(ox, oy))


func _hud(dst: Image) -> void:
	var n1: Image = PixelFont.make("CHRIS", Color(0.98, 0.98, 0.95), 2).get_image()
	var n2: Image = PixelFont.make("GIORGIS", Color(0.98, 0.98, 0.95), 2).get_image()
	var p1w: int = 40
	var p2w: int = 52
	var pill1: Image = PixelUI.name_pill(p1w, 10, Color(0.05, 0.05, 0.06)).get_image()
	var pill2: Image = PixelUI.name_pill(p2w, 10, Color(0.05, 0.05, 0.06)).get_image()
	pill1.resize(pill1.get_width() * 4, pill1.get_height() * 4, Image.INTERPOLATE_NEAREST)
	pill2.resize(pill2.get_width() * 4, pill2.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(pill1, Rect2i(0, 0, pill1.get_width(), pill1.get_height()), Vector2i(16, 8))
	dst.blend_rect(pill2, Rect2i(0, 0, pill2.get_width(), pill2.get_height()), Vector2i(1280 - 16 - p2w * 4, 8))
	dst.blend_rect(n1, Rect2i(0, 0, n1.get_width(), n1.get_height()), Vector2i(24, 12))
	dst.blend_rect(n2, Rect2i(0, 0, n2.get_width(), n2.get_height()), Vector2i(1280 - 24 - n2.get_width(), 12))
	var hp1: Image = PixelUI.tiny_hp(140, 10, Color(0.28, 0.82, 0.22), 1.0).get_image()
	var hp2: Image = PixelUI.tiny_hp(140, 10, Color(0.86, 0.18, 0.22), 0.62, true, 0.86).get_image()
	hp1.resize(hp1.get_width() * 4, hp1.get_height() * 4, Image.INTERPOLATE_NEAREST)
	hp2.resize(hp2.get_width() * 4, hp2.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(hp1, Rect2i(0, 0, hp1.get_width(), hp1.get_height()), Vector2i(16, 52))
	dst.blend_rect(hp2, Rect2i(0, 0, hp2.get_width(), hp2.get_height()), Vector2i(704, 52))
	var tbox: Image = PixelUI.timer_box().get_image()
	tbox.resize(tbox.get_width() * 4, tbox.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(tbox, Rect2i(0, 0, tbox.get_width(), tbox.get_height()), Vector2i(592, 6))
	var num: Image = PixelFont.make("99", Color(1, 1, 1), 3).get_image()
	dst.blend_rect(num, Rect2i(0, 0, num.get_width(), num.get_height()), Vector2i(640 - num.get_width() / 2, 36))


func _export_strips(def: CharacterDef, id: String) -> void:
	var frames: Dictionary = PixelFighterBake.bake(def)
	var dir := "res://.godot/%s_preview" % id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for key in ["idle", "walk", "run", "light", "heavy", "jump"]:
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
