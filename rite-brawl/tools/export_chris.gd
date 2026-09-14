extends SceneTree
## Headless dump of Chris idle / walk / kit frames for visual checks.


func _init() -> void:
	var f := FileAccess.open("res://data/characters/chris_xrisakis.json", FileAccess.READ)
	if f == null:
		push_error("missing chris json")
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	var def := CharacterDef.new()
	def.from_dict(parsed)
	var frames: Dictionary = PixelFighterBake.bake(def)
	var dir := "res://.godot/chris_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for key in ["idle", "walk", "run", "light", "heavy", "crouch", "jump"]:
		_export_strip(frames, key, dir)
	_export_strip(frames, "walk", dir, "walk_strip")
	_export_strip(frames, "light", dir, "light_strip")
	_export_strip(frames, "heavy", dir, "heavy_strip")
	print("exported chris preview frames")
	quit()


func _export_strip(frames: Dictionary, key: String, dir: String, fname: String = "") -> void:
	if not frames.has(key):
		return
	var arr: Array = frames[key]
	if arr.is_empty():
		return
	var out_name: String = fname if not fname.is_empty() else key
	if fname.is_empty():
		var img0: Image = (arr[0] as ImageTexture).get_image()
		img0.resize(img0.get_width() * 2, img0.get_height() * 2, Image.INTERPOLATE_NEAREST)
		img0.save_png(ProjectSettings.globalize_path("%s/%s.png" % [dir, key]))
		return
	var fw: int = (arr[0] as ImageTexture).get_width()
	var fh: int = (arr[0] as ImageTexture).get_height()
	var strip := Image.create(fw * arr.size(), fh, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	for i in arr.size():
		var fr: Image = (arr[i] as ImageTexture).get_image()
		strip.blit_rect(fr, Rect2i(0, 0, fw, fh), Vector2i(fw * i, 0))
	strip.save_png(ProjectSettings.globalize_path("%s/%s.png" % [dir, out_name]))
