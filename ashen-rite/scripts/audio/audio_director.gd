extends Node
## File soundtrack when present, synthesized SFX always.

const MUSIC_DIR := "res://assets/audio/music/"

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _cursor := 0
var _library: Dictionary = {}
var _music_menu: AudioStreamWAV
var _music_fight: AudioStreamWAV
var _catalog: Dictionary = {}
var _track_cache: Dictionary = {}
var _current_key: String = ""
var tracks: Array = []


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
	_load_catalog()
	_build_library()
	GameState.apply_audio_buses()
	play_music("menu")


func _load_catalog() -> void:
	var path := MUSIC_DIR + "catalog.json"
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_catalog = parsed.get("map", {})
	tracks = parsed.get("tracks", [])


func resolve_music_key(kind: String) -> String:
	if kind == "fight":
		if GameState.survival:
			return "survival"
		if GameState.time_attack:
			return "timeattack"
		if GameState.arcade:
			if GameState.arcade_queue.size() > 0 and GameState.arcade_index >= GameState.arcade_queue.size() - 1:
				return "final"
			return "arcade"
		if GameState.attract:
			return "attract"
		return "stage:" + GameState.arena_id
	if kind.begins_with("theme:"):
		return kind
	if kind.begins_with("stage:"):
		return kind
	return kind


func play_music(kind: String) -> void:
	var key: String = resolve_music_key(kind)
	if key == _current_key and music_player.playing:
		return
	var stream: AudioStream = _stream_for(key)
	if stream == null:
		stream = _music_fight if kind == "fight" else _music_menu
	if music_player.stream == stream and music_player.playing:
		_current_key = key
		return
	_current_key = key
	music_player.stream = stream
	music_player.volume_db = linear_to_db(clamp(GameState.music_volume, 0.001, 1.0))
	music_player.play()


func _stream_for(key: String) -> AudioStream:
	if _track_cache.has(key):
		return _track_cache[key]
	var fname: String = str(_catalog.get(key, ""))
	if fname.is_empty() and _catalog.has("menu"):
		if key.begins_with("stage:"):
			fname = str(_catalog.get("stage:grass_field", ""))
		elif key.begins_with("theme:"):
			fname = str(_catalog.get("theme:chris_xrisakis", ""))
	if fname.is_empty():
		return null
	var stream := _load_wav(MUSIC_DIR + fname)
	if stream:
		_track_cache[key] = stream
	return stream


func _load_wav(path: String) -> AudioStreamWAV:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var hdr := f.get_buffer(4).get_string_from_ascii()
	if hdr != "RIFF":
		return null
	f.get_32()
	var wave := f.get_buffer(4).get_string_from_ascii()
	if wave != "WAVE":
		return null
	var rate := 48000
	var ch := 2
	var data := PackedByteArray()
	while f.get_position() + 8 <= f.get_length():
		var cid := f.get_buffer(4).get_string_from_ascii()
		var sz := f.get_32()
		var next: int = f.get_position() + sz
		if cid == "fmt ":
			f.get_16()
			ch = f.get_16()
			rate = f.get_32()
			f.get_32()
			f.get_16()
			f.get_16()
			f.seek(next + (sz & 1))
		elif cid == "data":
			data = f.get_buffer(sz)
			break
		else:
			f.seek(next + (sz & 1))
	if data.is_empty():
		return null
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = ch == 2
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	var frame_bytes: int = 2 * maxi(ch, 1)
	s.loop_end = int(data.size() / frame_bytes)
	return s


func play(id: String, pitch: float = 1.0, vol: float = 1.0) -> void:
	if not _library.has(id):
		id = "ui"
	var p: AudioStreamPlayer = sfx_players[_cursor]
	_cursor = (_cursor + 1) % sfx_players.size()
	p.stop()
	p.stream = _library[id]
	p.pitch_scale = clamp(pitch, 0.6, 1.6)
	p.volume_db = linear_to_db(clamp(GameState.sfx_volume * vol, 0.001, 1.0))
	p.play()


func _build_library() -> void:
	_library["ui"] = _blip(880, 0.06, 0.25)
	_library["ui_confirm"] = _blip(520, 0.1, 0.3, 1.4)
	_library["ui_back"] = _blip(220, 0.12, 0.28, 0.6)
	_library["whoosh"] = _noise(0.08, 0.18, 1800)
	_library["punch"] = _hit(190, 0.09, 0.55)
	_library["heavy"] = _hit(90, 0.16, 0.85)
	_library["special"] = _sweep(140, 880, 0.28, 0.5)
	_library["ultimate"] = _sweep(60, 1400, 0.55, 0.7)
	_library["block"] = _hit(420, 0.07, 0.4)
	_library["grab"] = _hit(140, 0.12, 0.5)
	_library["hit_l"] = _hit(240, 0.08, 0.5)
	_library["hit_h"] = _hit(110, 0.14, 0.75)
	_library["ko"] = _sweep(180, 40, 0.6, 0.8)
	_library["victory"] = _fanfare()
	_library["defeat"] = _sweep(300, 70, 0.7, 0.55)
	_library["round"] = _blip(660, 0.18, 0.35, 0.5)
	_library["fight"] = _blip(330, 0.22, 0.4, 1.8)
	_library["clash"] = _hit(70, 0.12, 0.7)
	_library["land"] = _noise(0.07, 0.22, 900)
	_library["dash"] = _noise(0.09, 0.2, 1400)
	_library["meter"] = _blip(990, 0.16, 0.32, 1.6)
	_library["tick"] = _blip(740, 0.08, 0.28, 0.85)
	_library["tech"] = _blip(280, 0.1, 0.4, 1.8)
	_library["cheer"] = _fanfare()
	_library["parry"] = _blip(1240, 0.09, 0.38, 1.7)
	_library["super_call"] = _sweep(90, 1600, 0.42, 0.72)
	_music_menu = _music(false)
	_music_fight = _music(true)


func _pcm(frames: PackedFloat32Array, mix_rate: int = 22050, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(frames.size() * 2)
	for i in frames.size():
		var s := int(clamp(frames[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2] = s & 0xFF
		bytes[i * 2 + 1] = (s >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = frames.size()
	return wav


func _blip(freq: float, dur: float, amp: float, slide: float = 1.0) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var frames := PackedFloat32Array()
	frames.resize(n)
	for i in n:
		var t := float(i) / rate
		var env := (1.0 - t / dur)
		env *= env
		var f := freq * lerpf(1.0, slide, t / dur)
		frames[i] = sin(TAU * f * t) * amp * env
	return _pcm(frames)


func _hit(freq: float, dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var frames := PackedFloat32Array()
	frames.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(freq * 17)
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * 28.0)
		var noise := rng.randf_range(-1.0, 1.0) * 0.45
		frames[i] = (sin(TAU * freq * t) * 0.7 + noise) * amp * env
	return _pcm(frames)


func _noise(dur: float, amp: float, cutoff: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var frames := PackedFloat32Array()
	frames.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	var lp := 0.0
	var a := cutoff / rate
	for i in n:
		var t := float(i) / rate
		var env := 1.0 - t / dur
		var raw := rng.randf_range(-1.0, 1.0)
		lp = lerpf(lp, raw, clamp(a, 0.02, 1.0))
		frames[i] = lp * amp * env
	return _pcm(frames)


func _sweep(f0: float, f1: float, dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var frames := PackedFloat32Array()
	frames.resize(n)
	for i in n:
		var t := float(i) / rate
		var u := t / dur
		var env := sin(PI * u)
		var f := lerpf(f0, f1, u)
		frames[i] = sin(TAU * f * t) * amp * env
	return _pcm(frames)


func _fanfare() -> AudioStreamWAV:
	var rate := 22050
	var dur := 0.9
	var n := int(dur * rate)
	var frames := PackedFloat32Array()
	frames.resize(n)
	var notes := [392.0, 523.25, 659.25, 784.0]
	for i in n:
		var t := float(i) / rate
		var idx := clampi(int(t / 0.18), 0, notes.size() - 1)
		var env := exp(-(t - idx * 0.18) * 6.0)
		frames[i] = sin(TAU * notes[idx] * t) * 0.32 * env
		frames[i] += sin(TAU * notes[idx] * 2.0 * t) * 0.08 * env
	return _pcm(frames)


func _music(fight: bool) -> AudioStreamWAV:
	var rate := 22050
	var bpm := 148.0 if fight else 104.0
	var beat := 60.0 / bpm
	var bars := 8
	var dur := beat * 4.0 * bars
	var n := int(dur * rate)
	var frames := PackedFloat32Array()
	frames.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 if fight else 5
	var root := 58.27 if fight else 73.42
	var bass_pat := [0, 0, 7, 3, 0, 10, 7, 5, 0, 0, 8, 3, 0, 7, 10, 12] if fight else [0, 3, 7, 3, 0, 5, 7, 8, 0, 3, 5, 7, 8, 7, 5, 3]
	var lead_pat := [12, 15, 19, 15, 12, 22, 19, 15, 12, 14, 15, 19, 17, 15, 14, 12] if fight else [12, 15, 19, 17, 15, 14, 12, 15]
	for i in n:
		var t := float(i) / rate
		var eighth := beat * 0.5
		var step := int(t / eighth) % bass_pat.size()
		var f := root * pow(2.0, bass_pat[step] / 12.0)
		var bass := sin(TAU * f * t) * 0.15
		bass += sin(TAU * f * 0.5 * t) * 0.09
		var hat := 0.0
		if int(t / eighth) % 2 == 1:
			hat = rng.randf_range(-1.0, 1.0) * 0.045 * exp(-fmod(t, eighth) * 42.0)
		var kick := 0.0
		var kt := fmod(t, beat)
		if int(t / beat) % 2 == 0:
			kick = sin(TAU * (88.0 - kt * 90.0) * kt) * 0.24 * exp(-kt * 14.0)
		var snare := 0.0
		if int(t / beat) % 2 == 1:
			snare = rng.randf_range(-1.0, 1.0) * 0.12 * exp(-fmod(t, beat) * 18.0)
			snare += sin(TAU * 180.0 * kt) * 0.04 * exp(-kt * 16.0)
		var lead := 0.0
		var li := int(t / eighth) % lead_pat.size()
		var lf := root * pow(2.0, lead_pat[li] / 12.0)
		var lenv: float = 0.5 + 0.5 * sin(t * (10.0 if fight else 6.0))
		lead = sin(TAU * lf * t) * (0.055 if fight else 0.04) * lenv
		lead += sin(TAU * lf * 2.0 * t) * 0.018 * lenv
		var chord := 0.0
		if fight and int(t / beat) % 4 == 0:
			chord = sin(TAU * f * 2.0 * t) * 0.03 * exp(-kt * 6.0)
		frames[i] = clampf(bass + hat + kick + snare + lead + chord, -1.0, 1.0)
	return _pcm(frames, rate, true)
