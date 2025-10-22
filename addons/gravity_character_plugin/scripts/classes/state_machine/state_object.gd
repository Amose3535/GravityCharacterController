# state_object.gd
extends Resource
class_name StateObject
## The object that contains info about this state: activation conditions, previous states, active components child of ComponentContainer 

## A unique name that identifies this specific StateObject.
@export var state_name : String
## The conditions that have to be met so that this state to be triggered.
@export var activation_conditions : Array[StateActivationCondition]
## The components (or component classes) that are enabled when this state is active.
@export var component_map : Array




func _to_string() -> String:
	return state_name
