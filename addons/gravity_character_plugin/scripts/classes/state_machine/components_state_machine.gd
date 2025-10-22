# component_state_machine.gd
extends Node
class_name ComponentStateMachine
## A StateMachine that handles the activation and deactivation of the states based on external conditions.
##
## This approach to the state machine problem allows for a high degree of decoupling (the components don't have to know about other components and they only handle the logic and its application, not the conditions for its application)
## This decoupling also applies to states since i can just add a new state with its own conditions to be required and its own component activation "map".


## The controller (Just like in the components) should be a GravityCharacter3D. Which in the example scene is the player.
@export var controller : GravityCharacter3D
## Every state in the state machine. Each state has its own triggering conditions
@export var states : Array[StateObject]

var previous_state : StateObject
var current_state : StateObject
