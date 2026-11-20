@icon("./multiplayer_rigid_body_3d_synchronizer.svg")
class_name MultiplayerRigidBody3DSynchronizer
extends MultiplayerSynchronizer

var _body_parent: RigidBody3D

@export var interpolation_enabled: bool = true
@export var interpolation_speed: float = 15.0
@export var snap_distance: float = 4.0

var sync_position: Vector3 
var sync_rotation: Quaternion
var sync_linear_velocity: Vector3
var sync_angular_velocity: Vector3

func _ready() -> void:
	replication_config = SceneReplicationConfig.new()
	replication_config.add_property(NodePath(name + ":sync_position"))
	replication_config.add_property(NodePath(name + ":sync_rotation"))
	replication_config.add_property(NodePath(name + ":sync_linear_velocity"))
	replication_config.add_property(NodePath(name + ":sync_angular_velocity"))
	
	if get_parent() is not RigidBody3D:
		push_error("Parent is not RigidBody3D")
		set_physics_process(false)
		return
	_body_parent = get_parent() as RigidBody3D
	
	sync_position = _body_parent.global_position
	sync_rotation = _body_parent.global_transform.basis.get_rotation_quaternion()
	sync_linear_velocity = _body_parent.linear_velocity
	sync_angular_velocity = _body_parent.angular_velocity
	
	if not is_multiplayer_authority():
		_body_parent.freeze = true
		_body_parent.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		sync_position = _body_parent.global_position
		sync_rotation = _body_parent.global_transform.basis.get_rotation_quaternion()
		sync_linear_velocity = _body_parent.linear_velocity
		sync_angular_velocity = _body_parent.angular_velocity
		
	else:
		if not interpolation_enabled or sync_position.distance_squared_to(_body_parent.global_position) > snap_distance * snap_distance:
			_body_parent.global_position = sync_position
			_body_parent.global_transform.basis = Basis(sync_rotation)
			
		else:
			var weight: float = 1.0 - exp(-interpolation_speed * delta)
			_body_parent.global_position = _body_parent.global_position.lerp(sync_position, weight)
			
			var par_rot: Quaternion = _body_parent.global_transform.basis.get_rotation_quaternion()
			_body_parent.global_transform.basis = Basis(par_rot.slerp(sync_rotation, weight))
		
		_body_parent.linear_velocity = sync_linear_velocity
		_body_parent.angular_velocity = sync_angular_velocity


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_interpolation"):
		interpolation_enabled = not interpolation_enabled
