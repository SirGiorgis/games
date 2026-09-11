class_name PixelFighterBake
extends RefCounted

const W := 48
const H := 64
const SCALE := 4


static func bake(def: CharacterDef) -> Dictionary:
	var out := {}
	out["idle"] = [_frame(def, "idle", 0), _frame(def, "idle", 1), _frame(def, "idle", 2), _frame(def, "idle", 3)]
	out["walk"] = [_frame(def, "walk", 0), _frame(def, "walk", 1), _frame(def, "walk", 2), _frame(def, "walk", 3)]
	out["run"] = out["walk"]
	out["jump"] = [_frame(def, "jump", 0)]
	out["crouch"] = [_frame(def, "crouch", 0)]
	out["light"] = [_frame(def, "light", 0), _frame(def, "light", 1), _frame(def, "light", 2)]
	out["heavy"] = [_frame(def, "heavy", 0), _frame(def, "heavy", 1), _frame(def, "heavy", 2)]
	out["special"] = [_frame(def, "special", 0), _frame(def, "special", 1), _frame(def, "special", 2)]
	out["ultimate"] = [_frame(def, "ultimate", 0), _frame(def, "ultimate", 1), _frame(def, "ultimate", 2)]
	out["block"] = [_frame(def, "block", 0)]
	out["hit"] = [_frame(def, "hit", 0)]
	out["knockdown"] = [_frame(def, "knockdown", 0)]
	out["victory"] = [_frame(def, "victory", 0), _frame(def, "victory", 1)]
	out["defeat"] = [_frame(def, "knockdown", 0)]
	out["grab"] = [_frame(def, "grab", 0), _frame(def, "grab", 1)]
	return out


static func _frame(def: CharacterDef, pose: String, f: int) -> ImageTexture:
	var img := Pix.image(W, H)
	_paint(img, def, pose, f)
	Pix.outline(img, Color(0.05, 0.04, 0.06, 1))
	return Pix.tex(img)


static func _paint(img: Image, def: CharacterDef, pose: String, f: int) -> void:
	var skinny: bool = def.build == "lean" or def.width_scale < 0.9
	var racing: bool = def.style == "racing"
	var tw: int = 6 if skinny else (10 if def.build == "heavy" else 8)
	var cx := 24
	var foot := 61
	var bob := 0
	if pose == "idle":
		bob = 1 if f % 2 == 1 else 0
	var squat := 0
	if pose == "crouch" or pose == "block":
		squat = 8
	if pose == "hit":
		cx += 2
	if pose == "knockdown":
		_downed(img, def, tw)
		return

	var hip_y := foot - 16 + squat - bob
	var walk := 0
	if pose == "walk":
		walk = [-2, 2, -2, 2][f]
	var punch := 0
	if pose in ["light", "heavy", "grab"]:
		punch = [0, 4, 9][mini(f, 2)]
		if pose == "heavy":
			punch += 2
	var lean := 0
	if pose in ["special", "ultimate"]:
		lean = [1, 3, 2][mini(f, 2)]
		cx += lean

	var pants := def.outfit.darkened(0.22)
	var shoes := Color(0.07, 0.07, 0.08)
	var skin_dk := def.skin.darkened(0.22)
	# legs
	var ll := cx - 3 + (walk if walk < 0 else 0)
	var lr := cx + 1 + (walk if walk > 0 else 0)
	if pose == "jump":
		ll -= 2
		lr += 2
		hip_y -= 2
	Pix.rect(img, ll, hip_y, 3 if skinny else 4, foot - hip_y - 2, pants)
	Pix.rect(img, lr, hip_y, 3 if skinny else 4, foot - hip_y - 2, pants.lightened(0.06))
	Pix.rect(img, ll, foot - 2, 4, 2, shoes)
	Pix.rect(img, lr, foot - 2, 4, 2, shoes)

	# hips + torso (jacket)
	var torso_h := 16
	var torso_y := hip_y - torso_h
	Pix.rect(img, cx - tw / 2, hip_y - 3, tw + 1, 4, def.outfit)
	Pix.rect(img, cx - tw / 2, torso_y, tw + 1, torso_h, def.outfit)
	if racing:
		Pix.vline(img, cx, torso_y + 1, torso_h - 1, def.accent)
		Pix.vline(img, cx + 2, torso_y + 1, torso_h - 1, def.trim)
		Pix.rect(img, cx - tw / 2, torso_y, tw + 1, 3, def.accent.darkened(0.15))
	else:
		Pix.rect(img, cx - tw / 2 + 1, torso_y + 3, tw - 1, 2, def.trim)

	# arms
	var arm := def.outfit if racing else def.skin
	var hand := def.skin
	var arm_y := torso_y + 3
	var back_x := cx - tw / 2 - 3
	var front_x := cx + tw / 2 + 1
	if pose == "block":
		Pix.rect(img, cx - 1, arm_y, 3, 10, arm)
		Pix.rect(img, cx + 2, arm_y + 2, 3, 9, arm)
		Pix.rect(img, cx + 1, arm_y + 10, 3, 3, hand)
	elif pose == "victory":
		Pix.rect(img, back_x, arm_y, 3, 11, arm)
		Pix.rect(img, front_x + 1, torso_y - (10 if f == 1 else 8), 3, 12, arm)
		Pix.rect(img, front_x + 1, torso_y - (12 if f == 1 else 10), 3, 3, hand)
	elif punch > 0:
		Pix.rect(img, back_x, arm_y + 2, 3, 10, arm)
		Pix.rect(img, front_x, arm_y + 1, punch + 3, 3, arm)
		Pix.rect(img, front_x + punch + 2, arm_y, 4, 4, hand)
	elif pose in ["special", "ultimate"]:
		Pix.rect(img, back_x - 2, arm_y, 8, 3, arm)
		Pix.rect(img, front_x, arm_y - 2, 8, 3, arm)
		Pix.rect(img, front_x + 7, arm_y - 3, 3, 3, def.accent)
		# speed lines
		for i in 3:
			Pix.hline(img, 2, torso_y + 4 + i * 4, 6 + f, Color(def.accent, 0.7))
	else:
		Pix.rect(img, back_x, arm_y, 3, 11, arm)
		Pix.rect(img, front_x, arm_y + (1 if bob else 0), 3, 11, arm)
		Pix.rect(img, back_x, arm_y + 11, 3, 2, hand)
		Pix.rect(img, front_x, arm_y + 11 + (1 if bob else 0), 3, 2, hand)

	# head + hair
	var hx := cx - 4 + (2 if pose == "hit" else 0)
	var hy := torso_y - 10
	if pose == "jump":
		hy -= 1
	Pix.rect(img, hx, hy, 9, 9, def.skin)
	Pix.rect(img, hx + 1, hy + 8, 7, 2, skin_dk)
	# eyes
	var eye := def.eyes
	Pix.put(img, hx + 2, hy + 4, Color(0.08, 0.07, 0.07))
	Pix.put(img, hx + 6, hy + 4, Color(0.08, 0.07, 0.07))
	Pix.put(img, hx + 2, hy + 4, eye)
	Pix.put(img, hx + 6, hy + 4, eye)
	# hair / curls
	Pix.rect(img, hx - 1, hy - 2, 11, 4, def.hair)
	Pix.rect(img, hx - 1, hy + 1, 3, 5, def.hair)
	Pix.rect(img, hx + 7, hy + 1, 3, 4, def.hair)
	if skinny or racing:
		Pix.rect(img, hx + 1, hy - 3, 3, 2, def.hair.lightened(0.08))
		Pix.rect(img, hx + 5, hy - 4, 3, 3, def.hair)
		Pix.put(img, hx + 8, hy - 1, def.hair)
		Pix.put(img, hx - 1, hy + 5, def.hair)

	if pose == "ultimate":
		Pix.disc(img, cx + 10, torso_y + 6, 3 + f, Color(def.accent, 0.85))


static func _downed(img: Image, def: CharacterDef, _tw: int) -> void:
	var y := 46
	Pix.rect(img, 10, y + 6, 22, 5, def.outfit)
	Pix.rect(img, 30, y + 4, 10, 8, def.skin)
	Pix.rect(img, 32, y + 2, 10, 4, def.hair)
	Pix.rect(img, 8, y + 8, 6, 3, def.outfit.darkened(0.2))
	Pix.rect(img, 18, y + 10, 8, 3, def.outfit.darkened(0.15))
