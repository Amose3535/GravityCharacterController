# state_node.gd
@abstract
extends Node
class_name StateNode
## The object that contains info about this state: activation conditions, previous states, active components child of ComponentContainer.
##
## The node that has a script which inherits from this class must be a direct child of the FSM node. Make sure that all nodes which have a script that inherits from this class also are direct children of the FSM node.

## The signal emitted when the state is transitioned
signal transitioned(new_state_name : String, state : StateNode)

## A unique name that identifies this specific StateNode. This is used to ask the state machine to transition to a new state so make sure to type it correctly (case INsensitive)
@export var state_name : String

## Function called when the node enters the current state
func _on_enter() -> void:
	pass

## Function called when the node exits the current state
func _on_exit() -> void:
	pass


## Equivalent of _process() for the state nodes. remember to use THAT when processing stuff and not _process().
func _on_update(delta : float) -> void:
	pass

## Equivalent of _physics_process() for the state nodes. remember to use THAT when processing stuff and not _physics_process().
func _on_physics_update(delta : float) -> void:
	pass
