# state_player_idle.gd
extends PlayerState
class_name PlayerIdleState
## The class that represents the idle state in the FSM. Like all State nodes, it must be a direct child of the FSM node.

func _ready() -> void:
	state_name = "idle"

func _on_update(delta : float) -> void:
	if controller.get_vertical_velocity_scalar() > 0 and !controller.is_on_floor() and !controller.is_on_wall():
		transitioned.emit("jump", self)
		return
	
	if controller.get_vertical_velocity_scalar() < 0 and !controller.is_on_floor() and !controller.is_on_wall():
		transitioned.emit("fall", self)
		return
	
	if !controller.get_horizontal_velocity().is_equal_approx(Vector3.ZERO) and controller.is_on_floor():
		transitioned.emit("walk", self)
		return
	
