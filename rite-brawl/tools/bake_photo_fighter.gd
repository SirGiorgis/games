extends SceneTree
## Bake a portrait photo into a 128x128 model sheet + preview strips.

const PhotoSprite := preload("res://scripts/pixel/photo_fighter_sprite.gd")
const TARGET_ID := "hoodrich_stacks"


func _init() -> void:
	var path := "res://data/characters/%s.json" % TARGET_ID
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("missing character json: %s" % path)
		quit(1)
		return
	var def := CharacterDef.new().from_dict(JSON.parse_string(f.get_as_text()))
	f.close()
	var out: String = PhotoSprite.save_baked(def)
	if out.is_empty():
		push_error("bake failed")
		quit(1)
		return
	PixelFighterBake._model_cache.erase(def.id)
	var frames: Dictionary = PixelFighterBake.bake(def)
	var dir := "res://.godot/%s_preview" % def.id
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for key in ["idle", "walk", "light", "heavy", "jump"]:
		_save_strip(frames, key, dir)
	print("baked %s -> %s" % [def.name, out])
	quit()


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
	solo.resize(solo.get_width() * 2, solo.get_height() * 2, Image.INTERPOLATE_NEAREST)
	solo.save_png(ProjectSettings.globalize_path("%s/%s.png" % [dir, key]))
