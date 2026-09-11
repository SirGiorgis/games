class_name FighterVisual
extends Node2D
## Pixel-art fighter. Same API as the old puppet visual.

const SCALE := PixelFighterBake.SCALE
const FW := PixelFighterBake.W
const FH := PixelFighterBake.H

var def: CharacterDef
var facing: int = 1
var pose: String = "idle"
var attack_u: float = 0.0
var flash: float = 0.0
var trail_timer: float = 0.0

var _sprite: Sprite2D
var _frames: Dictionary = {}
var _time := 0.0


func build(d: CharacterDef) -> void:
	def = d
	_frames = PixelFighterBake.bake(d)
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = false
	_sprite.texture = _tex("idle", 0)
	_sprite.position = Vector2(-FW * SCALE / 2, -FH * SCALE)
	_sprite.scale = Vector2(SCALE, SCALE)
	add_child(_sprite)
	var sh := Sprite2D.new()
	var simg := Pix.image(20, 6, Color(0, 0, 0, 0))
	Pix.dither_fill(simg, 0, 2, 20, 3, Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.15))
	sh.texture = Pix.tex(simg)
	sh.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sh.centered = true
	sh.position = Vector2(0, 4)
	sh.scale = Vector2(SCALE, SCALE)
	sh.z_index = -2
	add_child(sh)


func set_pose_name(p: String) -> void:
	pose = p


func pulse_hit() -> void:
	flash = 1.0


func _process(delta: float) -> void:
	_time += delta
	flash = max(0.0, flash - delta * 8.0)
	if _sprite == null:
		return
	_sprite.texture = _current_tex()
	_sprite.flip_h = facing < 0
	_sprite.modulate = Color.WHITE.lerp(Color(1.6, 1.6, 1.6), flash)
	if pose in ["walk", "run", "special", "ultimate"] and trail_timer <= 0.0:
		trail_timer = 0.07
		_ghost()
	trail_timer = max(0.0, trail_timer - delta)


func _current_tex() -> Texture2D:
	var key := pose
	if not _frames.has(key):
		key = "idle"
	var arr: Array = _frames[key]
	if pose in ["light", "clight", "jlight", "heavy", "cheavy", "jheavy", "special", "ultimate", "grab", "jump"]:
		var idx := clampi(int(attack_u * arr.size()), 0, arr.size() - 1)
		return arr[idx]
	var spd: float = 14.0 if pose == "run" else (10.0 if pose == "walk" else (7.0 if pose == "victory" else 5.5))
	var idx2: int = int(_time * spd) % arr.size()
	return arr[idx2]


func _tex(key: String, idx: int) -> Texture2D:
	var arr: Array = _frames.get(key, [])
	if arr.is_empty():
		return ImageTexture.new()
	return arr[clampi(idx, 0, arr.size() - 1)]


func _ghost() -> void:
	if def == null:
		return
	var g := Sprite2D.new()
	g.texture = _sprite.texture
	g.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	g.centered = false
	g.global_position = _sprite.global_position
	g.scale = _sprite.scale
	g.flip_h = _sprite.flip_h
	g.modulate = Color(def.accent, 0.35)
	g.z_index = -1
	var p := get_parent()
	if p:
		p.add_child(g)
		var tw := g.create_tween()
		tw.tween_property(g, "modulate:a", 0.0, 0.16)
		tw.tween_callback(g.queue_free)
