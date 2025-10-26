# state_player_on_wall.gd
extends PlayerState
class_name PlayerOnWallState
## The class that represents the OnWall state in the FSM. Like all State nodes, it must be a direct child of the FSM node.
##
## Specifically this state happens when the player has jumped on a wall

func _ready() -> void:
	state_name = "on_wall"

func _on_update(delta : float) -> void:
	# If the velocity vector is near to zero and is on floor, then transition to idle
	if controller.velocity.is_equal_approx(Vector3.ZERO) and controller.is_on_floor():
		transitioned.emit("idle", self)
		return
	
	if controller.get_vertical_velocity_scalar() < 0 and !controller.is_on_floor() and !controller.is_on_wall():
		transitioned.emit("fall", self)
		return
	
	if !controller.get_horizontal_velocity().is_equal_approx(Vector3.ZERO) and controller.is_on_floor():
		transitioned.emit("walk", self)
		return
	
	
