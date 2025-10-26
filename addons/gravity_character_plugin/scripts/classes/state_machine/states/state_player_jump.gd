# state_player_jump.gd
extends PlayerState
class_name PlayerJumpState
## The class that represents the Jump state in the FSM. Like all State nodes, it must be a direct child of the FSM node.

func _ready() -> void:
	state_name = "jump"

func _on_update(delta : float) -> void:
	# If the velocity vector is near to zero and is on floor, then transition to idle
	if controller.is_on_floor():
		if controller.velocity.is_equal_approx(Vector3.ZERO):
			transitioned.emit("idle", self)
			return
		
		if !controller.get_horizontal_velocity().is_equal_approx(Vector3.ZERO):
			transitioned.emit("walk", self)
			return
		
	else: #(NOT ON FLOOR)
		if controller.is_on_wall():
			if  controller.get_vertical_velocity_scalar() < 0:
				transitioned.emit("on_wall", self)
				return
		
		else: #(NOT ON WALL)
			if controller.get_vertical_velocity_scalar() < 0:
				transitioned.emit("fall", self)
				return
			
