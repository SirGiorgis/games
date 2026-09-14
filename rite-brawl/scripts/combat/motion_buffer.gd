class_name MotionBuffer
extends RefCounted
## MUGEN-style facing-relative motion + double-tap detection.

var facing: int = 1
var _hist: Array[int] = []
var _fwd_edge_age: float = 99.0
var _back_edge_age: float = 99.0
var _prev_fwd: bool = false
var _prev_back: bool = false

const MAX_LEN := 20
const TAP_WIN := 0.28


func reset() -> void:
	_hist.clear()
	_fwd_edge_age = 99.0
	_back_edge_age = 99.0
	_prev_fwd = false
	_prev_back = false


func push(left: bool, right: bool, up: bool, down: bool, face: int, delta: float) -> Dictionary:
	facing = face
	var fwd: bool = right if face > 0 else left
	var back: bool = left if face > 0 else right
	var n := 5
	if down and fwd:
		n = 3
	elif down and back:
		n = 1
	elif up and fwd:
		n = 9
	elif up and back:
		n = 7
	elif down:
		n = 2
	elif up:
		n = 8
	elif fwd:
		n = 6
	elif back:
		n = 4
	if _hist.is_empty() or _hist[_hist.size() - 1] != n:
		_hist.append(n)
		if _hist.size() > MAX_LEN:
			_hist.pop_front()
	_fwd_edge_age += delta
	_back_edge_age += delta
	var dbl_fwd := false
	var dbl_back := false
	if fwd and not _prev_fwd:
		if _fwd_edge_age <= TAP_WIN:
			dbl_fwd = true
		_fwd_edge_age = 0.0
	if back and not _prev_back:
		if _back_edge_age <= TAP_WIN:
			dbl_back = true
		_back_edge_age = 0.0
	_prev_fwd = fwd
	_prev_back = back
	return {
		"dir": n,
		"fwd": fwd,
		"back": back,
		"run": dbl_fwd,
		"backdash": dbl_back,
		"qcf": _has_seq([2, 3, 6]) or _has_seq([2, 6]),
		"dp": _has_seq([6, 2, 3]) or _has_seq([6, 2, 6]),
		"qcf2": _has_seq([2, 3, 6, 2, 3, 6]) or _has_seq([2, 6, 2, 6]),
	}


func consume_motion() -> void:
	_hist.clear()


func _has_seq(need: Array) -> bool:
	var i := 0
	for d in _hist:
		if int(d) == int(need[i]):
			i += 1
			if i >= need.size():
				return true
	return false
