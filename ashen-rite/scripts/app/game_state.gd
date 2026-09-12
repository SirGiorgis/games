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
