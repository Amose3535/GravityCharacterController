# component_state_machine.gd
@tool
extends StateMachine
class_name ComponentStateMachine
## A StateMachine that handles the activation and deactivation of the states based on external conditions.
##
## This approach to the state machine problem allows for a high degree of decoupling (the components don't have to know about other components and they only handle the logic and its application, not the conditions for its application)
## This decoupling also applies to states since i can just add a new state with its own conditions to be required and its own component activation "map".


## The controller (Just like in the components) should be a GravityCharacter3D. Which in the example scene is the player.
@export var controller : GravityController3D = null:
	get:
		if controller: return controller
		var parent: Node = get_parent()
		if parent is GravityController3D: controller = parent
		return controller

## The list of all components that should NEVER be turned off. This is defined here and not in any State or state-derived class because this should be the unique source of truth for globally active components.
@export var permanent_components : Array[String] = []


func _process(delta: float) -> void:
	_update_states_controller()
	if Engine.is_editor_hint():
		# editor only logic here
		return
	#print(current_state.state_name)
	# parent class' physics process function (maintains logic)
	super._process(delta)

func _update_states_controller() -> void:
	if controller:
		for player_state in get_player_states():
			if !player_state.controller:
				player_state.controller = controller

func get_player_states() -> Array[PlayerState]:
	var states : Array[StateNode] = get_states()
	var player_states : Array[PlayerState] = []
	for state in states:
		if (state is PlayerState):
			player_states.append(state)
	return player_states
