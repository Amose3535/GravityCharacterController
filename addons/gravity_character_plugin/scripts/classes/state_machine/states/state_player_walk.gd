extends PlayerState
class_name PlayerWalkState


func _on_physics_update(delta : float) -> void:
	if controller.get_vertical_velocity() > 0:
		transitioned.emit("jump", self)
		return
	
	if controller.get_vertical_velocity() < 0:
		transitioned.emit("fall", self)
		return
	
	if controller.get_horizontal_velocity().length() > 0:
		transitioned.emit("walk", self)
		return
	
