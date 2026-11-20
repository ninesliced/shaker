class_name InteractionRayCast3D
extends RayCast3D

signal focused(area: InteractionArea3D)
signal unfocused(area: InteractionArea3D)

var is_focused: bool = false
var target_area: InteractionArea3D
var target_point: Vector3

var is_interacting: bool = false

func _physics_process(delta: float) -> void:
	_update_collider(delta)
	
	if target_area:
		target_area._update_focus(target_point)


func start_interact():
	if target_area:
		target_area._start_interact(self, target_point)
	is_interacting = true


func end_interact():
	if is_interacting and target_area:
		target_area._end_interact(self)
	is_interacting = false


func _update_collider(delta):
	target_point = get_collision_point()
	
	var new_collider = get_collider()
	if is_colliding() and new_collider is InteractionArea3D:
		is_focused = true
		if new_collider != target_area:
			focused.emit(new_collider)
			if is_interacting and target_area:
				target_area._end_interact(self)
			target_area = new_collider
			if is_interacting:
				target_area._start_interact(self, target_point)
			target_area._focus(self)
		
	else:
		is_focused = false
		if target_area != null:
			unfocused.emit(target_area)
			target_area._unfocus()
			if is_interacting:
				target_area._end_interact(self)
			target_area = null
