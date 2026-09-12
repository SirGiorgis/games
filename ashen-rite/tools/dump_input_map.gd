extends SceneTree
## Print DualSense bindings so we can verify the InputMap without a pad.


func _init() -> void:
	var cm: Node = load("res://scripts/input/control_map.gd").new()
	cm._ready()
	var keys := [
		"p1_left", "p1_right", "p1_up", "p1_down",
		"p1_light", "p1_heavy", "p1_special", "p1_block", "p1_grab", "p1_ultimate", "p1_pause",
		"menu_confirm", "menu_back", "menu_up", "menu_down",
	]
	for a in keys:
		if not InputMap.has_action(a):
			print("MISSING %s" % a)
			continue
		var bits: PackedStringArray = PackedStringArray()
		for ev in InputMap.action_get_events(a):
			bits.append(ev.as_text())
		print("%s :: %s" % [a, " | ".join(bits)])
	quit()
