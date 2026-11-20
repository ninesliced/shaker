class_name State
extends AbstractState

var state_machine: StateMachine
var is_in_state: bool = false

func _ready() -> void:
	assert(get_parent() is StateMachine)
	state_machine = get_parent()


func travel_to(state_name: StringName, params: Dictionary = {}):
	state_machine.travel_to(state_name, params)
