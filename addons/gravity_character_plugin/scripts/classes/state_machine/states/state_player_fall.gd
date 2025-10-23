# state_player_fall.gd
extends PlayerState
class_name PlayerFallState
## The class that represents the Fall state in the FSM. Like all State nodes, it must be a direct child of the FSM node.

func _ready() -> void:
	state_name = "fall"

func _on_physics_update(delta : float) -> void:
	# If the velocity vector is near to zero and is on floor, then transition to idle
	if controller.velocity.is_equal_approx(Vector3.ZERO) and controller.is_on_floor():
		transitioned.emit("idle", self)
		return
	
	# If the horizontal component of the velocity vector is greater than zero and on flooor, then transition to walk
	if controller.get_horizontal_velocity().length() > 0 and controller.is_on_floor():
		transitioned.emit("walk", self)
		return
	
