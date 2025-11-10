# state_player_idle.gd
extends ComponentState
class_name PlayerIdleState
## The class that represents the idle state in the FSM. Like all State nodes, it must be a direct child of the FSM node.

func _ready() -> void:
	state_name = "idle"

func _on_update(delta : float) -> void:
	if controller.is_on_floor():
		if !controller.get_horizontal_velocity().is_equal_approx(Vector3.ZERO):
			transitioned.emit("walk", self)
			return
	else:
		if controller.get_vertical_velocity_scalar() > 0:
				transitioned.emit("jump", self)
				return
		if controller.is_on_wall():
			pass
		else:
			if controller.get_vertical_velocity_scalar() < 0:
				transitioned.emit("fall", self)
				return
	
