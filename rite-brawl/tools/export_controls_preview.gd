extends SceneTree
## Headless DualSense / keyboard controls board.


func _init() -> void:
	var field := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	field.fill(Color(0.10, 0.08, 0.12))
	_panel(field, 40, 88, 600, 560)
	_panel(field, 640, 88, 600, 560)

	var title := PixelFont.make("CONTROLS", Color(0.95, 0.22, 0.28), 4).get_image()
	_blit(field, title, 640 - title.get_width() / 2, 16)

	_label(field, "KEYBOARD", Color(0.95, 0.78, 0.35), 340, 104)
	var kb := [
		"P1  A/D WALK",
		"W JUMP   S CROUCH",
		"J LIGHT   K HEAVY",
		"L SPECIAL   U BLOCK",
		"I THROW   O SUPER",
		"ESC / P PAUSE",
		"FWD+U PARRY",
		"L+U BURST",
		"",
		"P2  ARROWS MOVE",
		"Z X C  LIGHT HEAVY SPECIAL",
		"V B N  BLOCK THROW SUPER",
	]
	for i in kb.size():
		_wrap(field, kb[i], Color(0.92, 0.90, 0.86), 64, 150 + i * 32, 40)

	_label(field, "DUALSENSE  PS5", Color(0.55, 0.85, 1.0), 940, 104)
	var pad := [
		"LS / DPAD     MOVE",
		"SQUARE        LIGHT",
		"TRIANGLE      HEAVY",
		"CIRCLE        SPECIAL",
		"L1 / L2       BLOCK",
		"R1            THROW",
		"R2            SUPER",
		"OPTIONS       PAUSE",
		"CROSS         MENU OK",
		"CIRCLE        MENU BACK",
		"PAD 1 = P1    PAD 2 = P2",
		"FWD+L1 PARRY  CIRCLE+L1 BURST",
	]
	for i in pad.size():
		var col := Color(0.98, 0.86, 0.32) if i == pad.size() - 1 else Color(0.88, 0.90, 0.94)
		_wrap(field, pad[i], col, 664, 150 + i * 32, 36)

	var out := "res://.godot/controls_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	field.save_png(ProjectSettings.globalize_path("%s/dualsense.png" % out))
	print("controls preview -> %s/dualsense.png" % out)
	quit()


func _panel(dst: Image, x: int, y: int, w: int, h: int) -> void:
	var p := Image.create(w, h, false, Image.FORMAT_RGBA8)
	p.fill(Color(0.06, 0.06, 0.08, 0.72))
	dst.blend_rect(p, Rect2i(0, 0, w, h), Vector2i(x, y))


func _label(dst: Image, text: String, col: Color, cx: int, y: int) -> void:
	var img: Image = PixelFont.make(text, col, 2).get_image()
	_blit(dst, img, cx - img.get_width() / 2, y)


func _wrap(dst: Image, text: String, col: Color, x: int, y: int, wrap: int) -> void:
	if text.is_empty():
		return
	var img: Image = PixelFont.make(text, col, 2, wrap).get_image()
	_blit(dst, img, x, y)


func _blit(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))
