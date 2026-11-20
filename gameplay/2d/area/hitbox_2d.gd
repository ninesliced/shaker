## Area that can deal damage to Hurtboxes
@icon("./hitbox_2d.svg")
class_name Hitbox2D
extends Area2D

@export var enabled: bool = true :
	set(value):
		enabled = value
		if enabled:
			_enable()
		else:
			_disable()
@export var damage: float = 1.0

signal on_hurtbox_hit(hurtbox: Hurtbox2D)

@export var damages_enemies: bool = false
@export var damages_players: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _disable() -> void:
	monitoring = false


func _enable() -> void:
	monitoring = true


func disable() -> void:
	enabled = false
	_disable()


func enable() -> void:
	enabled = true
	_enable()


func _on_area_entered(area: Area2D):
	if not enabled:
		return
	
	if area is Hurtbox2D:
		var hurtbox = area as Hurtbox2D
		var success = hurtbox.on_hitbox_entered(self)
		on_hurtbox_hit.emit(hurtbox)


func _on_area_exited(area: Area2D):
	if not enabled:
		return
	
	if area is Hurtbox2D:
		var hurtbox = area as Hurtbox2D
		hurtbox.on_hitbox_exited(self)
