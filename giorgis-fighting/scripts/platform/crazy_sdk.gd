extends Node
## CrazyGames HTML5 SDK. No-ops in the Godot editor and desktop builds.

const PixelLabelScr := preload("res://scripts/pixel/pixel_label.gd")

var mute_audio := false
var ad_mute := false
var environment := "disabled"

var _sdk_ready := false
var _init_started := false
var _blocking := false
var _ad_state := ""
var _ad_wait := 0.0
var _script_injected := false
var _layer: CanvasLayer
var _root: Control
var _lbl


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	if not OS.has_feature("web"):
		_sdk_ready = true
		environment = "disabled"
		set_process(false)
		return
	set_process(true)


func ads_available() -> bool:
	return _sdk_ready and environment in ["local", "crazygames"]


func audio_blocked() -> bool:
	return mute_audio or ad_mute


func gameplay_start() -> void:
	if GameState.attract:
		return
	_js("try{window.CrazyGames.SDK.game.gameplayStart()}catch(e){}")


func gameplay_stop() -> void:
	_js("try{window.CrazyGames.SDK.game.gameplayStop()}catch(e){}")


func happytime() -> void:
	if GameState.attract or GameState.training:
		return
	_js("try{window.CrazyGames.SDK.game.happytime()}catch(e){}")


func request_midgame() -> bool:
	return await request_ad("midgame")


func request_rewarded() -> bool:
	return await request_ad("rewarded")


func request_ad(kind: String) -> bool:
	if not ads_available():
		return kind == "midgame"
	if _blocking:
		return false
	_blocking = true
	_ad_state = "pending"
	_ad_wait = 0.0
	var start_ms: int = Time.get_ticks_msec()
	_show_block()
	_js(
		"(function(){window.__gfAdState='pending';try{window.CrazyGames.SDK.ad.requestAd('%s',{adStarted:function(){window.__gfAdState='started'},adFinished:function(){window.__gfAdState='finished'},adError:function(){window.__gfAdState='error'}})}catch(e){window.__gfAdState='error'}})()"
		% kind
	)
	while _ad_state != "finished" and _ad_state != "error":
		await get_tree().process_frame
		if Time.get_ticks_msec() - start_ms > 28000:
			_ad_state = "error"
			break
	var ok: bool = _ad_state == "finished"
	ad_mute = false
	_hide_block()
	_blocking = false
	GameState.apply_audio_buses()
	return ok


func _process(_delta: float) -> void:
	if not OS.has_feature("web"):
		return
	if not _sdk_ready:
		_try_init()
	else:
		_poll_mute()
	if _blocking:
		_poll_ad()


func _input(_event: InputEvent) -> void:
	if _blocking:
		get_viewport().set_input_as_handled()


func _try_init() -> void:
	if not _script_injected:
		_script_injected = true
		_js(
			"(function(){if(window.CrazyGames){window.__gfCgLoaded=true;return}var s=document.createElement('script');s.src='https://sdk.crazygames.com/crazygames-sdk-v3.js';s.onload=function(){window.__gfCgLoaded=true};s.onerror=function(){window.__gfCgLoaded=false;window.__gfCgReady=true;window.__gfCgEnv='disabled'};document.head.appendChild(s)})()"
		)
	var loaded: Variant = _js("window.__gfCgLoaded===true||typeof window.CrazyGames!=='undefined'")
	if not loaded:
		return
	if not _init_started:
		_init_started = true
		_js(
			"(function(){if(window.__gfCgInitStarted)return;window.__gfCgInitStarted=true;try{window.CrazyGames.SDK.init().then(function(){window.__gfCgReady=true;window.__gfCgEnv=window.CrazyGames.SDK.environment||'disabled';window.__gfMute=!!(window.CrazyGames.SDK.game&&window.CrazyGames.SDK.game.settings&&window.CrazyGames.SDK.game.settings.muteAudio);try{window.CrazyGames.SDK.game.addSettingsChangeListener(function(s){window.__gfMute=!!(s&&s.muteAudio)})}catch(e){}}).catch(function(){window.__gfCgReady=true;window.__gfCgEnv='disabled'})}catch(e){window.__gfCgReady=true;window.__gfCgEnv='disabled'}})()"
		)
	var ready: Variant = _js("window.__gfCgReady===true")
	if not ready:
		return
	_sdk_ready = true
	environment = str(_js("window.__gfCgEnv||'disabled'"))
	mute_audio = bool(_js("!!window.__gfMute"))
	GameState.apply_audio_buses()


func _poll_ad() -> void:
	var st: String = str(_js("window.__gfAdState||''"))
	if st == "started" and not ad_mute:
		ad_mute = true
		GameState.apply_audio_buses()
	if st in ["started", "finished", "error", "pending"]:
		_ad_state = st


func _poll_mute() -> void:
	var m: bool = bool(_js("!!window.__gfMute"))
	if m == mute_audio:
		return
	mute_audio = m
	GameState.apply_audio_buses()


func _js(code: String) -> Variant:
	if not OS.has_feature("web"):
		return null
	return JavaScriptBridge.eval(code, true)


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 90
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_lbl = PixelLabelScr.new()
	_root.add_child(_lbl)
	_root.visible = false


func _show_block() -> void:
	if _lbl:
		_lbl.set_pix("PLEASE WAIT", 4, Color(1, 0.92, 0.45))
		_lbl.set_centered(1280)
		_lbl.position = Vector2(0, 330)
	_root.visible = true


func _hide_block() -> void:
	_root.visible = false
