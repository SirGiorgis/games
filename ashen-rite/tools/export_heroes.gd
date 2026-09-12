extends SceneTree
## Export Chris + Stacks preview strips for visual checks.


const IDS := ["chris_xrisakis", "hoodrich_stacks"]


func _init() -> void:
	for id in IDS:
		_export_id(id)
	print("exported hero previews")
	quit()


func _export_id(id: String) -> void:
	PixelFighterBake.clear_cache(id)
	var f := FileAccess.open("res://data/characters/%s.json" % id, FileAccess.READ)
	if f == null:
		push_error("missing %s" % id)
		return
	var def := CharacterDef.new().from_dict(JSON.parse_string(f.get_as_text()))
	f.close()
	var frames: Dictionary = PixelFighterBake.bake(def)
	var dir := "res://.godot/%s_preview" % id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for key in ["idle", "walk", "run", "light", "heavy", "jump"]:
		_save_strip(frames, key, dir)
	print("  %s -> %s" % [def.name, dir])


func _save_strip(frames: Dictionary, key: String, dir: String) -> void:
	if not frames.has(key):
		return
	var arr: Array = frames[key]
	if arr.is_empty():
		return
	var fw: int = (arr[0] as ImageTexture).get_width()
	var fh: int = (arr[0] as ImageTexture).get_height()
	var strip := Image.create(fw * arr.size(), fh, false, Image.FORMAT_RGBA8)
	strip.fill(Color(0, 0, 0, 0))
	for i in arr.size():
		var fr: Image = (arr[i] as ImageTexture).get_image()
		strip.blit_rect(fr, Rect2i(0, 0, fw, fh), Vector2i(fw * i, 0))
	strip.save_png(ProjectSettings.globalize_path("%s/%s_strip.png" % [dir, key]))
	var solo: Image = (arr[0] as ImageTexture).get_image()
	solo.resize(solo.get_width() * 3, solo.get_height() * 3, Image.INTERPOLATE_NEAREST)
	solo.save_png(ProjectSettings.globalize_path("%s/%s.png" % [dir, key]))
