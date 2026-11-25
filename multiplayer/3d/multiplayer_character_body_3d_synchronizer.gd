@icon("./multiplayer_character_body_3d_synchronizer.svg")
class_name MultiplayerCharacterBody3DSynchronizer
extends MultiplayerSynchronizer

# Notes:
# - Transform3D sends 12 floats/tick vs. 7 floats for Vector3 + Quaternion. If bandwith 
#   is a priority, this could be refactored so that it sends "sync_position" + "sync_rotation"
#   instead of "sync_transform".
# - For now, this synchronizer ignores scale.

var _body_parent: CharacterBody3D

@export var interpolation_enabled: bool = true
@export var interpolation_speed: float = 15.0
@export var snap_distance: float = 4.0

var sync_transform: Transform3D
var sync_velocity: Vector3

var _relative_object_path: NodePath: set = _set_relative_object_path
var relative_object: Node3D

var _local_transform: Transform3D
var _snap_next_sync_flag: bool = true

func _enter_tree() -> void:
	replication_config = SceneReplicationConfig.new()
	replication_config.add_property(NodePath(name + ":sync_transform"))
	replication_config.add_property(NodePath(name + ":sync_velocity"))
	replication_config.add_property(NodePath(name + ":_relative_object_path"))


func _ready() -> void:
	if get_parent() is not CharacterBody3D:
		push_error("Parent is not CharacterBody3D")
		set_physics_process(false)
		return
	_body_parent = get_parent() as CharacterBody3D
	
	sync_transform = _body_parent.global_transform
	sync_velocity = _body_parent.velocity
	
	if not _relative_object_path.is_empty():
		relative_object = get_node_or_null(_relative_object_path)


func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		_sync_from_authority()
	else:
		_sync_as_authority(delta)


func _sync_from_authority() -> void:
	var offset_tranform = Transform3D.IDENTITY
	if is_instance_valid(relative_object): # Translate relative transform to global
		offset_tranform = relative_object.global_transform.affine_inverse()
	var final_transform = offset_tranform * _body_parent.global_transform
	
	sync_transform = final_transform
	sync_velocity = _body_parent.velocity


func _sync_as_authority(delta: float) -> void:
	var interp_weight: float = 1.0 - exp(-interpolation_speed * delta)
	
	var local_position = _local_transform.origin
	var local_rotation = _local_transform.basis.get_rotation_quaternion()
	var sync_position = sync_transform.origin
	var sync_rotation = sync_transform.basis.get_rotation_quaternion()
	
	var snap_next_sync = \
		_snap_next_sync_flag or \
		not interpolation_enabled or \
		local_position.distance_squared_to(sync_position) > snap_distance * snap_distance
	if _snap_next_sync_flag:
		_snap_next_sync_flag = false
	
	var sync_rotation_norm = sync_rotation.normalized()
	if snap_next_sync:
		_local_transform = sync_transform
	else:
		local_position = local_position.lerp(sync_position, interp_weight)
		local_rotation = local_rotation.slerp(sync_rotation_norm, interp_weight)
		_local_transform = Transform3D(Basis(local_rotation), local_position)
	
	var offset_tranform = Transform3D.IDENTITY
	if is_instance_valid(relative_object): # Translate relative transform to global
		offset_tranform = relative_object.global_transform

	var target_transform = offset_tranform * _local_transform
	_body_parent.global_transform = target_transform
	_body_parent.velocity = sync_velocity


func _input(event: InputEvent) -> void:
	pass
	#if event.is_action_pressed("debug_toggle_interpolation"):
		#interpolation_enabled = not interpolation_enabled


func set_relative_object(value: Node3D) -> void:
	if value:
		_relative_object_path = value.get_path()
	else:
		_relative_object_path = ""


func _set_relative_object_path(value: NodePath) -> void:
	if value == _relative_object_path:
		return
	_relative_object_path = value
	if not is_node_ready():
		return
	
	var new_obj = null if value.is_empty() else (get_node_or_null(value) as Node3D)
	
	if not is_multiplayer_authority():
		var old_obj_transf = relative_object.global_transform if is_instance_valid(relative_object) else Transform3D.IDENTITY
		var new_obj_transf_inv = new_obj.global_transform.affine_inverse() if is_instance_valid(new_obj) else Transform3D.IDENTITY
		
		# local transform = (old location in global space) in new local space
		_local_transform = new_obj_transf_inv * (old_obj_transf * _local_transform)
		
	relative_object = new_obj
