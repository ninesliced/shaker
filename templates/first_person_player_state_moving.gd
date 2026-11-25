#class_name StateMoving
extends State

const SPEED = 5.0
const ACCEL = 30.0
const JUMP_VELOCITY = 4.5

@onready var player: Player = $"../.."

func _ready() -> void:
	pass


func _on_enter_state(params: Dictionary = {}):
	pass


func _on_exit_state():
	pass


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		player.velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		player.velocity.x = move_toward(player.velocity.x, direction.x * SPEED, ACCEL * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * SPEED, ACCEL * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, ACCEL * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, ACCEL * delta)
	
	player.move_and_slide()
