# state_machine.gd
extends Node
class_name StateMachine
##The base class for all state machines.



## The initial state of the StateMachine
@export var initial_state : StateNode = null:
	set(new_state):
		initial_state = new_state
		current_state = initial_state

## Every state in the state machine. Each state has its own triggering conditions
var states : Array[StateNode]
## The current state of the StateMachine
var current_state : StateNode


func _ready() -> void:
	if Engine.is_editor_hint():
		# Editor only logic
		return
	states = get_states() # Setup the states array
	_connect_states_transition() # connect every state in "states" to _on_state_transitioned()
	_enter_initial_state() # Finally enter the initial state if present

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		# editor only logic here
		return
	_process_states(delta)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		# editor only logic here
		return
	_physics_process_states(delta)

## Calls the _on_update() function in all states
func _process_states(delta : float) -> void:
	if Engine.is_editor_hint():
		# editor only logic here
		return
	for state in states:
		if state == current_state: # processes only the current active state
			state._on_update(delta)
	
	# prima
	await get_tree().create_timer(20).timeout
	# dopo

## Calls the _on_physics_update() function in all states
func _physics_process_states(delta : float) -> void:
	if Engine.is_editor_hint():
		# editor only logic here
		return
	for state in states:
		if state == current_state: # processes only the current active state
			state._on_physics_update(delta)

## Connects all states' 'transitioned' signal to _on_state_transitioned
func _connect_states_transition() -> void:
	for state in states:
		state.transitioned.connect(_on_state_transitioned)

## Applies the logic for state transition
func _on_state_transitioned(new_state_name, state) -> void:
	# If a state which is not the current state tries to transition, return since it's not his authority.
	if state != current_state: 
		print("A state node which isn't the current state tried requersting a transition")
		return
	
	# Get the new StateNode based on the new state name
	var new_state : StateNode = get_state_by_name(new_state_name, false)
	if !new_state: 
		print("Couldn't find a new state with name %s as a child of this FSM."%new_state_name)
		return
	
	print("Exiting %s and entering %s"%[current_state.state_name, new_state.state_name])
	# Call exit function on the current state
	if current_state: current_state._on_exit()
	# Call enter function on the previous state
	new_state._on_enter()
	# Assign new state to the current state
	current_state = new_state

## Function that applies logic for initial state entering
func _enter_initial_state() -> void:
	if initial_state:
		initial_state._on_enter()
		current_state = initial_state

## API call that returns an array of type Array[StateNode]that contains all StateNode-s that are direct children of the StateMachine node
func get_states() -> Array[StateNode]:
	var state_node_arr : Array[StateNode] = []
	var children : Array[Node] = get_children()
	if children.size() == 0: return []
	for child in children:
		if child is StateNode:
			state_node_arr.append(child)
	return state_node_arr

func get_state_by_name(state_name : String, case_sensitive : bool) -> StateNode:
	var name_to_be_checked : String = state_name if case_sensitive else state_name.to_lower()
	for state in states:
		var comparison_name : String = state.state_name if case_sensitive else state.state_name.to_lower()
		if name_to_be_checked == comparison_name:
			return state
	return null
