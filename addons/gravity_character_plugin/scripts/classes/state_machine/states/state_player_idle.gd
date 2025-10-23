# state_player_idle.gd
extends PlayerState
class_name PlayerIdleState
## The class that represents the idle state in the FSM. Like all State nodes, it must be a direct child of the FSM node.


func _ready() -> void:
	state_name = "idle"
	if !controller: print("UH OH")

func _on_enter() -> void:
	_edit_components_state()

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
	
