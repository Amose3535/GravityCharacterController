# state_player_dash.gd
extends ComponentState
class_name PlayerDashState
## A state for dashing

func _ready() -> void:
	state_name = "dash"

func _on_update(delta : float) -> void:
	# If the velocity vector is near to zero and is on floor, then transition to idle
	if !controller.component_container.get_component_by_name("dash_component").dashed:
		if controller.is_on_floor():
			if controller.velocity.is_equal_approx(Vector3.ZERO):
				transitioned.emit("idle", self)
				return
			
			if !controller.get_horizontal_velocity().is_equal_approx(Vector3.ZERO):
				transitioned.emit("walk", self)
				return
		else:
			if controller.is_on_wall():
				transitioned.emit("on_wall", self)
			else:
				if controller.get_vertical_velocity_scalar() > 0:
					transitioned.emit("jump", self)
					return
				
				if controller.get_vertical_velocity_scalar() < 0:
					transitioned.emit("fall", self)
					return
	
