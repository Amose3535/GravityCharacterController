# player_state.gd
@abstract
extends StateNode
class_name PlayerState
## PlayerState is a base class for all player-related states and contains important information such as the reference to the player_controller node (With base class of type GravityCharacter3D) and more coming in the future.


## A reference to the controller node (base type GravityCharacter3D)
@export var controller : GravityController3D = null


## A map with all the components that are active when the child class state is the current active FSM state.[br]
## If a component isn't present but is in the permanent_components then it willa lways be active no matter what
@export var active_components : Array[String] 

var components : Array[BaseComponent] = []:
	get:
		var components_candidates := controller.component_container.get_components() 
		if components_candidates != components:
			components = components_candidates
		return components

func _on_enter() -> void:
	_edit_components_state() # sets the necessary components to active and deactivates the rest

## The internal function used to toggle on active components and off inactive ones
func _edit_components_state() -> void:
	if !controller or !controller.component_container: return #Skips logic
	var parent : Node = get_parent()
	if !(parent is ComponentStateMachine): return # Skips logic
	for component in components:
		component.active = \
		(component.component_name in (parent as ComponentStateMachine).permanent_components) \
		or \
		(component.component_name in active_components)
