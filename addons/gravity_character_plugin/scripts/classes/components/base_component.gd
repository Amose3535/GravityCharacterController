# base_component.gd
@icon("res://addons/gravity_character_plugin/assets/textures/icons/ComponentIcon.png")
extends Node
class_name BaseComponent
## The base class from which all components will inherit from. Only used to get the referenct to the 

## The name of the component. It's reccomended to have a unique identifier for your component so that a state machine (like the one provided) can reference that class script through the name directly.
@export var component_name : String = ""

## The parameters that determines wether the component should be active or not.
@export var active : bool = true:
	set(new_state):
		active = new_state
		process_mode = Node.PROCESS_MODE_INHERIT if new_state else Node.PROCESS_MODE_DISABLED

## The node that will handle all component nodes. This is usually the owner (GravityCharacter3D)
@export var controller : GravityCharacter3D:
	get:
		#print("GETTING CONTROLLER NODE: controller=%s | CORRECT_SETUP=%s"%[str(controller),str(CORRECT_SETUP)])
		CORRECT_SETUP = (controller != null)
		return controller

var CORRECT_SETUP : bool = true:
	set(new_state):
		CORRECT_SETUP = new_state
		process_mode = Node.PROCESS_MODE_INHERIT if new_state else Node.PROCESS_MODE_DISABLED
