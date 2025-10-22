extends Node3D

@onready var floor_object: StaticBody3D = $Objects/Floor/FloorObject

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	#var gravity_dir : Vector3 = floor_object.global_position - %Player.global_position
	#%Player.gravity_direction = gravity_dir
	pass
