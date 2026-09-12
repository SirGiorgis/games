extends Node

signal settings_changed

enum Difficulty { EASY, NORMAL, HARD, EXPERT }
enum ScreenId { BOOT, MENU, SELECT, OPTIONS, CONTROLS, MATCH, RESULT }

var difficulty: Difficulty = Difficulty.NORMAL
var p1_character_id: String = "chris_xrisakis"
var p2_character_id: String = "hoodrich_stacks"
var p2_is_cpu: bool = true
var arena_id: String = "grass_field"
var random_arena: bool = false

var p1_rounds: int = 0
var p2_rounds: int = 0
var rounds_to_win: int = 2
var last_winner: int = -1
var last_was_timeout: bool = false
var last_was_perfect: bool = false
var last_was_double: bool = false
var last_was_dramatic: bool = false
var match_active: bool = false

var master_volume: float = 0.85
var music_volume: float = 0.55
var sfx_volume: float = 0.9
var shake_strength: float = 1.0
var show_hitboxes: bool = false
var training: bool = false
var attract: bool = false
var dummy_mode: String = "cpu"
var arcade: bool = false
var arcade_index: int = 0
var arcade_queue: PackedStringArray = PackedStringArray()
var arcade_score: int = 0
var match_max_combo: int = 0
var match_damage: float = 0.0
var match_hits: int = 0
var survival: bool = false
var survival_wave: int = 0
var time_attack: bool = false

var custom_description: String = "Male fighter, tall, athletic build, black hair, black jacket, aggressive personality, lightning-based powers."
var custom_photo_path: String = "res://data/characters/refs/custom.png"


func reset_match_score() -> void:
	p1_rounds = 0
	p2_rounds = 0
	last_winner = -1
	last_was_timeout = false
	last_was_perfect = false
	last_was_double = false
	last_was_dramatic = false
	match_active = true
	match_max_combo = 0
	match_damage = 0.0
	match_hits = 0


func begin_arcade(p1_id: String) -> void:
	arcade = true
	survival = false
	time_attack = false
	arcade_index = 0
	arcade_score = 0
	p1_character_id = p1_id
	p2_is_cpu = true
	training = false
	attract = false
	rounds_to_win = 1
	arcade_queue = PackedStringArray()
	var rival: String = "hoodrich_stacks" if p1_id != "hoodrich_stacks" else "chris_xrisakis"
	for id in CharacterCatalog.ids():
		if id == p1_id or id == "custom" or id == rival:
			continue
		arcade_queue.append(id)
	arcade_queue.append(rival)
	if arcade_queue.is_empty():
		arcade_queue.append("hoodrich_stacks")
	p2_character_id = arcade_queue[0]


func next_arcade_bout() -> bool:
	arcade_index += 1
	if arcade_index >= arcade_queue.size():
		return false
	p2_character_id = arcade_queue[arcade_index]
	reset_match_score()
	return true


func begin_survival(p1_id: String) -> void:
	survival = true
	arcade = false
	time_attack = false
	survival_wave = 1
	arcade_score = 0
	p1_character_id = p1_id
	p2_is_cpu = true
	training = false
	attract = false
	rounds_to_win = 1
	_pick_survival_foe()


func next_survival_wave() -> void:
	survival_wave += 1
	_pick_survival_foe()
	reset_match_score()


func _pick_survival_foe() -> void:
	var ids := CharacterCatalog.ids()
	var pool: Array[String] = []
	for id in ids:
		if id != p1_character_id and id != "custom":
			pool.append(id)
	if pool.is_empty():
		p2_character_id = "hoodrich_stacks"
		return
	p2_character_id = pool[(survival_wave - 1) % pool.size()]


func begin_time_attack(p1_id: String) -> void:
	time_attack = true
	arcade = false
	survival = false
	arcade_score = 0
	p1_character_id = p1_id
	p2_is_cpu = true
	training = false
	attract = false
	rounds_to_win = 1


func end_arcade() -> void:
	arcade = false
	survival = false
	time_attack = false
	rounds_to_win = 2


func note_hit(combo: int, dmg: float) -> void:
	match_hits += 1
	match_damage += dmg
	if combo > match_max_combo:
		match_max_combo = combo
	if arcade:
		arcade_score += int(round(dmg)) + combo * 10
	if survival:
		arcade_score += int(round(dmg)) + combo * 12


func difficulty_name() -> String:
	match difficulty:
		Difficulty.EASY:
			return "EASY"
		Difficulty.NORMAL:
			return "NORMAL"
		Difficulty.HARD:
			return "HARD"
		Difficulty.EXPERT:
			return "EXPERT"
	return "NORMAL"


func cycle_difficulty(dir: int = 1) -> void:
	var v := int(difficulty) + dir
	if v < 0:
		v = int(Difficulty.EXPERT)
	if v > int(Difficulty.EXPERT):
		v = 0
	difficulty = v as Difficulty
	settings_changed.emit()


func apply_audio_buses() -> void:
	var master_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(clamp(master_volume, 0.001, 1.0)))
