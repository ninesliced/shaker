## An Entity is a game object that can move and interact with the world.
class_name Actor2D
extends CharacterBody2D

@export var deceleration := 1000.0

var captured_entity: Actor2D

@onready var state_machine: StateMachine = $StateMachine


func knockback_from_entity(entity: Actor2D, amount: float) -> void:
	var dir = global_position.direction_to(entity.global_position)
	apply_impulse(-dir * amount)


func apply_impulse(vector: Vector2) -> void:
	velocity += vector


func has_state(state_name: NodePath) -> bool:
	if not state_machine:
		return false
	
	return state_machine.has_node(state_name)


func decelerate(delta: float):
	velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
