extends SceneTree
## Headless cabinet preview: new stages + expanded roster.


func _init() -> void:
	PixelFighterBake.clear_cache()
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.10, 0.08, 0.12))

	var title := PixelFont.make("GIORGIS FIGHTING", Color(0.95, 0.22, 0.28), 4).get_image()
	_blit(field, title, 640 - title.get_width() / 2, 16)
	var sub := PixelFont.make("CHRIS  GIORGIS  MAKO  FOGAS", Color(0.95, 0.82, 0.35), 2).get_image()
	_blit(field, sub, 640 - sub.get_width() / 2, 64)

	var stages := [
		"grass_field", "moonlit_temple", "neon_street", "the_pit", "crimson_keep",
		"tidal_dock", "snow_ridge", "desert_gate", "clocktower", "bamboo_yard",
		"storm_bridge", "sunset_pier", "void_garden",
	]
	for i in stages.size():
		var tex: Image = PixelArenaBake.texture(stages[i]).get_image()
		tex.convert(Image.FORMAT_RGBA8)
		tex.resize(176, 99, Image.INTERPOLATE_NEAREST)
		var col: int = i % 7
		var row: int = int(i / 7)
		_blit(field, tex, 28 + col * 180, 96 + row * 108)

	var ids := [
		"chris_xrisakis", "hoodrich_stacks", "mako", "fogas",
	]
	for i in ids.size():
		var def := _def(ids[i])
		var feet_x: int = 160 + i * 320
		var feet_y: int = 560
		_stamp_fighter(field, def, "ultimate", 8, feet_x, feet_y, i % 2 == 1)
		var nm: Image = PixelFont.make(def.callsign(), def.accent, 1).get_image()
		_blit(field, nm, feet_x - nm.get_width() / 2, feet_y + 8)
		var ult: Image = PixelFont.make(def.ultimate_name.to_upper(), Color(0.95, 0.82, 0.35), 1).get_image()
		_blit(field, ult, feet_x - ult.get_width() / 2, feet_y + 24)

	var foot := PixelFont.make("CHRIS  GIORGIS  MAKO  FOGAS", Color(0.85, 0.78, 0.62), 2).get_image()
	_blit(field, foot, 640 - foot.get_width() / 2, 688)

	var out := "res://.godot/gig_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/cabinet.png" % out))
	print("gig preview -> %s/cabinet.png" % out)
	quit()


func _def(id: String) -> CharacterDef:
	var f := FileAccess.open("res://data/characters/%s.json" % id, FileAccess.READ)
	return CharacterDef.new().from_dict(JSON.parse_string(f.get_as_text()))


func _stamp_fighter(dst: Image, def: CharacterDef, pose: String, frame: int, feet_x: int, feet_y: int, flip: bool) -> void:
	var frames: Dictionary = PixelFighterBake.bake(def)
	var arr: Array = frames.get(pose, frames["idle"])
	var tex: ImageTexture = arr[clampi(frame, 0, arr.size() - 1)]
	var src: Image = tex.get_image()
	var sc: float = float(maxi(PixelFighterBake.SCALE - 1, 3))
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
