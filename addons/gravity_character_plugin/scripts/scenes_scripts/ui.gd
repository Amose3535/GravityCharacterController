extends CanvasLayer

@onready var state: Label = $State

var controller : GravityController3D:
	get:
		return get_parent()

func _process(delta: float) -> void:
	state.text = controller.get_statemachine_if_present().current_state.state_name
