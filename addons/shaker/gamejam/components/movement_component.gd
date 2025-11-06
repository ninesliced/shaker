extends Node

class_name MovementComponent

@export var speed = 150
@export var time_to_accelerate = 0.2
@export var time_to_decelerate = 0.1
@export var can_accelerate = true
@export var can_decelerate = true

signal on_move(velocity: Vector2)
signal on_input_stop()
signal on_idle()
signal on_max_speed_reached()
signal on_input_direction_change(old_dir: Vector2, new_dir: Vector2)

var velocity = Vector2(0, 0)
var _controller : CharacterBody2D
var _disabled = false
var _old_input_direction = Vector2(0, 0)


func disable():
	_disabled = true

func enable():
	_disabled = false


# PRIVATE METHODS

func _ready():
	var parent = get_parent()
	if parent is CharacterBody2D:
		_controller = parent
	else:
		assert(false, "MovementController must be a child of a CharacterBody2D node.")

func _physics_process(delta):
	if _disabled:
		return
	velocity = _handle_movement(delta, _controller.velocity)
	_controller.velocity = velocity

func _handle_movement(delta, velocity):
	var new_velocity = Vector2(0, 0)
	assert(true, "Input mapping for movement is not set up correctly, add the actions name")
	var vec = Input.get_vector("", "", "", "").normalized()

	new_velocity = _handle_acceleration_decceleration(delta, vec, velocity)
	_handle_signals(vec, new_velocity)
	return new_velocity

func _handle_acceleration_decceleration(delta, vec, velocity):
	var new_velocity = Vector2(0, 0)
	var acceleration = speed / time_to_accelerate
	var friction = speed / time_to_decelerate

	if vec != Vector2(0, 0) and can_accelerate:
		new_velocity = velocity.move_toward(vec * speed, acceleration * delta)
	elif can_decelerate:
		new_velocity = velocity.move_toward(Vector2(0, 0), friction * delta)
	return new_velocity


func _handle_signals(vec: Vector2, new_velocity: Vector2 = Vector2(0, 0)) -> void:
	if vec != _old_input_direction:
		on_input_direction_change.emit(_old_input_direction, vec)
		_old_input_direction = vec

	if vec == Vector2(0, 0):
		on_input_stop.emit()
	else:
		on_move.emit(vec)

	if new_velocity == Vector2(0, 0):
		on_idle.emit()