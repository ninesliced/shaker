## Area that can recieve damage from hitboxes.
@icon("./hurtbox_2d.svg")
class_name Hurtbox2D
extends Area2D

## Whether to ignore sibling hitboxes. 
@export var ignore_sibling_hitboxes := true
@export var enabled: bool = true :
	set(value):
		enabled = value
		monitorable = value


## Emitted when entered in collision with a hitbox.
signal hitbox_entered(area: Hitbox2D)
signal hitbox_exited(area: Hitbox2D)


func on_hitbox_entered(hitbox: Hitbox2D) -> bool:
	if not is_hittable(hitbox):
		return false
	
	hitbox_entered.emit(hitbox)
	return true


func on_hitbox_exited(hitbox: Hitbox2D):
	hitbox_exited.emit(hitbox)


func is_hittable(hitbox: Hitbox2D):
	if ignore_sibling_hitboxes and hitbox.get_parent() == get_parent():
		return false
	return true


func disable() -> void:
	enabled = false


func enable() -> void:
	enabled = true
