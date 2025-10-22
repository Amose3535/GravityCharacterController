# base_component.gd
#@tool
@icon("res://assets/ComponentIcon.png")
extends Node
class_name BaseComponent

## The node that will handle all component nodes. This is usually the owner (GravityController3D)
@export var controller : GravityController3D:
	get:
		#print("GETTING CONTROLLER NODE: controller=%s | CORRECT_SETUP=%s"%[str(controller),str(CORRECT_SETUP)])
		CORRECT_SETUP = (controller != null)
		return controller

var CORRECT_SETUP : bool = true

#var _config_warns : PackedStringArray = PackedStringArray()
#
#func _get_configuration_warnings() -> PackedStringArray:
	#_config_warns = PackedStringArray()
	#
	#if controller == null:
		#_config_warns.append("Make sure that the parent of this node is not null.")
	#
	#return _config_warns
