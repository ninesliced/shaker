#class_name Player
extends CharacterBody3D

var mouse_sensitivity: float = 0.01

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var camera_raycast: InteractionRayCast3D = $Head/CameraRaycast
@onready var label_3d: Label3D = $Label3D
@onready var sprite_3d: Sprite3D = $Head/Sprite3D
@onready var spawn_marker: Marker3D = $Head/SpawnMarker
@onready var hand_marker: Marker3D = $HandPosition
@onready var voice_chat: VoiceChat3D = $VoiceChat3D
@onready var state_machine: StateMachine = $StateMachine

var constrain_y_rot: = false
var constrain_y_rot_min := 0.0
var constrain_y_rot_max := 0.0
var constrain_y_rot_relative_obj: Node3D

const BALL = preload("uid://y0nej82nqnnk")

var interacted_object: InteractionArea3D
var picked_up_object: Pickupable

var current_vehicle: VehicleBody3D
var current_vehicle_path: String
var _last_vehicle_transform: Transform3D = Transform3D.IDENTITY

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	camera.make_current()


func _physics_process(delta: float) -> void:
	pass


func _process(delta: float) -> void:
	_apply_y_rot_constraint()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI/2, PI/2)
		_apply_y_rot_constraint()
	
	if event.is_action_pressed("interact"):
		var obj = camera_raycast.target_area
		if obj:
			_on_interact(obj)
	
	if event.is_action_released("interact"):
		camera_raycast.end_interact()
		interacted_object = null


func _apply_y_rot_constraint():
	if not constrain_y_rot:
		return
	
	var ref_basis = Basis.IDENTITY
	if is_instance_valid(constrain_y_rot_relative_obj):
		ref_basis = constrain_y_rot_relative_obj.global_transform.basis.orthonormalized()
	
	var rel_basis = ref_basis.inverse() * global_transform.basis.orthonormalized()
	var rel_euler = rel_basis.get_euler()
	rel_euler.y = clampf(rel_euler.y, constrain_y_rot_min, constrain_y_rot_max)
	
	global_transform.basis = ref_basis * Basis.from_euler(rel_euler)


func get_interacted_object() -> InteractionArea3D:
	return camera_raycast.target_area


func get_interacted_position():
	if camera_raycast.is_focused:
		return camera_raycast.target_point
	return null


func _on_interact(object: InteractionArea3D) -> void:
	interacted_object = object
	camera_raycast.start_interact()
