class_name Hitbox
extends Area2D

signal landed(hurtbox: Area2D, attack: Dictionary)

var owner_fighter: Fighter
var attack: Dictionary = {}
var active: bool = false
var already: Dictionary = {}


func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 4
	collision_mask = 8
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50, 36)
	cs.shape = rect
	cs.position = Vector2(40, -70)
	add_child(cs)
	area_entered.connect(_on_area)


func configure(size: Vector2, offset: Vector2) -> void:
	var cs := get_child(0) as CollisionShape2D
	var rect := cs.shape as RectangleShape2D
	rect.size = size
	cs.position = offset


func arm(atk: Dictionary) -> void:
	attack = atk
	already.clear()
	active = true
	monitoring = true
	visible = GameState.show_hitboxes


func disarm() -> void:
	active = false
	monitoring = false
	already.clear()


func _on_area(area: Area2D) -> void:
	if not active:
		return
	if area == null:
		return
	var fid = area.get_meta("fighter_id", -1)
	if fid == owner_fighter.fighter_id:
		return
	if already.has(fid):
		return
	already[fid] = true
	landed.emit(area, attack)
