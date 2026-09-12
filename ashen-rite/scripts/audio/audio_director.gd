extends Node
## Runtime-synthesized SFX and music. No imported audio files required.

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _cursor := 0
var _library: Dictionary = {}
var _music_menu: AudioStreamWAV
var _music_fight: AudioStreamWAV


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)
	_build_library()
	GameState.apply_audio_buses()
	play_music("menu")


func play_music(kind: String) -> void:
	var stream: AudioStreamWAV = _music_fight if kind == "fight" else _music_menu
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.volume_db = linear_to_db(clamp(GameState.music_volume, 0.001, 1.0))
	music_player.play()


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
	var bpm := 140.0 if fight else 100.0
	var beat := 60.0 / bpm
	var bars := 4
	var dur := beat * 4.0 * bars
	var n := int(dur * rate)
	var frames := PackedFloat32Array()
	frames.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 if fight else 3
	var root := 55.0 if fight else 73.4
	var pattern := [0, 0, 7, 3, 0, 10, 7, 0] if fight else [0, 3, 7, 3, 0, 5, 7, 8]
	for i in n:
		var t := float(i) / rate
		var step := int(t / (beat * 0.5)) % pattern.size()
		var f := root * pow(2.0, pattern[step] / 12.0)
		var bass := sin(TAU * f * t) * 0.16
		bass += sin(TAU * f * 0.5 * t) * 0.08
		var hat := 0.0
		if int(t / (beat * 0.5)) % 2 == 1:
			hat = rng.randf_range(-1.0, 1.0) * 0.04 * exp(-fmod(t, beat * 0.5) * 40.0)
		var kick := 0.0
		if int(t / beat) % 2 == 0:
			var kt := fmod(t, beat)
			kick = sin(TAU * (90.0 - kt * 80.0) * kt) * 0.22 * exp(-kt * 12.0)
		var lead := 0.0
		if fight:
			lead = sin(TAU * f * 4.0 * t) * 0.05 * (0.5 + 0.5 * sin(t * 8.0))
		frames[i] = bass + hat + kick + lead
	return _pcm(frames, rate, true)
