@icon("./interaction_area_3d.svg")
class_name InteractionArea3D
extends Area3D

signal focused(raycast: InteractionRayCast3D)
signal unfocused(raycast: InteractionRayCast3D)
signal interacted(raycast: InteractionRayCast3D, target_point: Vector3)
signal interaction_ended(raycast: InteractionRayCast3D)

var interacted_raycast: InteractionRayCast3D
var interact_point: Vector3


func _update_focus(new_interact_point: Vector3) -> void:
	interact_point = new_interact_point


func _focus(raycast: InteractionRayCast3D) -> void:
	interacted_raycast = raycast
	focused.emit(raycast)


func _unfocus() -> void:
	unfocused.emit(interacted_raycast)
	interacted_raycast = null


func _start_interact(raycast: InteractionRayCast3D, target_point: Vector3) -> void:
	interacted.emit(raycast, target_point)


func _end_interact(raycast: InteractionRayCast3D) -> void:
	interaction_ended.emit(raycast)
