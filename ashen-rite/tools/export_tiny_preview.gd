extends SceneTree
## Headless Tiny Fight-style preview: arena + Chris vs Stacks + HUD mock.


func _init() -> void:
	PixelFighterBake.clear_cache()
	var arena: Image = PixelArenaBake.texture("grass_field").get_image()
	arena.convert(Image.FORMAT_RGBA8)
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.66, 0.80, 0.88))
	arena.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	field.blit_rect(arena, Rect2i(0, 0, 1280, 720), Vector2i.ZERO)

	var chris := _def("chris_xrisakis")
	var stacks := _def("hoodrich_stacks")
	_stamp_fighter(field, chris, "idle", 0, 500, 620, false)
	_stamp_fighter(field, stacks, "idle", 0, 760, 620, true)
	_stamp_fighter(field, chris, "light", 5, 200, 620, false)
	_stamp_fighter(field, stacks, "heavy", 7, 1080, 620, true)

	_hud(field)
	var out := "res://.godot/tiny_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/fight.png" % out))

	_export_strips(chris, "chris_xrisakis")
	_export_strips(stacks, "hoodrich_stacks")
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
	var hp1: Image = PixelUI.tiny_hp(132, 9, Color(0.28, 0.82, 0.22), 1.0).get_image()
	var hp2: Image = PixelUI.tiny_hp(132, 9, Color(0.86, 0.18, 0.22), 0.72, true).get_image()
	hp1.resize(hp1.get_width() * 4, hp1.get_height() * 4, Image.INTERPOLATE_NEAREST)
	hp2.resize(hp2.get_width() * 4, hp2.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(hp1, Rect2i(0, 0, hp1.get_width(), hp1.get_height()), Vector2i(16, 24))
	dst.blend_rect(hp2, Rect2i(0, 0, hp2.get_width(), hp2.get_height()), Vector2i(736, 24))
	var tbox: Image = PixelUI.timer_box().get_image()
	tbox.resize(tbox.get_width() * 4, tbox.get_height() * 4, Image.INTERPOLATE_NEAREST)
	dst.blend_rect(tbox, Rect2i(0, 0, tbox.get_width(), tbox.get_height()), Vector2i(596, 8))
	var num: Image = PixelFont.make("99", Color(1, 1, 1), 3).get_image()
	dst.blend_rect(num, Rect2i(0, 0, num.get_width(), num.get_height()), Vector2i(640 - num.get_width() / 2, 28))


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
