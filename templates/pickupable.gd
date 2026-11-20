class_name Pickupable
extends RigidBody3D

@onready var interaction_area: InteractionArea3D = $InteractionArea3D
@onready var state_machine: StateMachine = $StateMachine
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var interaction_collision_shape: CollisionShape3D = $InteractionArea3D/CollisionShape3D

var is_picked_up: bool = false
var holder_player: Player

var _reset_motion_flag: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	pass


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _reset_motion_flag:
		_reset_motion_flag = false
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		constant_force = Vector3.ZERO
		constant_torque = Vector3.ZERO


func reset_motion():
	_reset_motion_flag = true


@rpc("any_peer", "call_local")
func pick_up(player_path: NodePath, new_authority: int):
	var player = get_node_or_null(player_path)
	if not player or player is not Player:
		push_error("Player path invalid: " + str(player_path))
		return
	
	is_picked_up = true
	
	# Only for local client
	collision_shape.disabled = true
	interaction_collision_shape.disabled = true
	
	set_multiplayer_authority(new_authority)
	holder_player = player
	state_machine.travel_to("PickedUp")


@rpc("any_peer", "call_local")
func drop(drop_transform: Transform3D):
	is_picked_up = false
	
	# Only for local client
	collision_shape.disabled = false
	interaction_collision_shape.disabled = false
	
	global_transform = drop_transform
	
	set_multiplayer_authority(1)
	state_machine.travel_to("Normal")


# To be implemented by child classes
func use():
	pass
