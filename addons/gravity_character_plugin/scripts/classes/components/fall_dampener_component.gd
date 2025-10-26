# fall_dampener_component.gd
extends BaseComponent
class_name FallDampener
## A component that dampens fall when an input is pressed


## How much of the original velocity along the gravity direction should be removed each frame when pressing the jump key. Best to be kept > 1 and not too big
@export var variable_jump_dampening : float = 2


func _physics_process(delta: float) -> void:
	_dampen_fall(delta) # Has an effect when constant_jump is disabled

## The function used to dampen the fall, only happens when it's not on floor and jump button is pressed.
func _dampen_fall(delta : float) -> void:
	if Input.is_action_pressed("jump") and !controller.is_on_floor():
		#print("DAMPENING FALL")
		if controller.get_vertical_velocity_scalar() > 0:
			controller.velocity -= (controller.gravity_direction * controller.gravity * delta)/variable_jump_dampening # A variable_jump_dampening fraction of the formula for gravity is dampened
