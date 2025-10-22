# state_activation_condition.gd
@tool
extends Resource
class_name StateActivationCondition
## A class that wraps the condition for the activation of a state

enum Operators {
	LESS_THAN,
	LESS_OR_EQUAL_THAN,
	EQUALS,
	GREATER_OR_EQUAL_THAN,
	GREATER_THAN
}

@export var variable : String
@export var operator : Operators = Operators.EQUALS
## Workaround to have an operand of pickable type in the editor (since i can't export Variants) without having to handle an array directly.[br]Unfortunately i either do this, export a string (looks ass and it's hard to work with tbh), or have a shitass of work only to make this function.
@export var operand : Array:
	set(new_operand):
		if new_operand.size() > 1:
			new_operand.resize(1)
		operand = new_operand
