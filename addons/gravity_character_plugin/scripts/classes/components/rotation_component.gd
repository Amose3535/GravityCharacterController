# rotation_component.gd
extends BaseComponent
class_name RotationComponent
## A component used to handle mouse rotation



## Sensitivity for the mouse/analog stick X axis (Yaw)
@export_range(0.0, 1.0, 0.0001) var mouse_sensitivity_x : float = 0.002
## Sensitivity for the mouse/analog stick Y axis (Pitch)
@export_range(0.0, 1.0, 0.0001) var mouse_sensitivity_y : float = 0.002
## Maximum vertical angle for the head rotation (in degrees)
@export_range(0.1, 89.9, 0.100) var max_vertical_angle : float = 89.9
## Enable / Disable strafe tilt
@export var strafe_tilt_enabled: bool = true
## Determines how much can the head tilt from the rest position to left/right
@export var max_stilt_angle: float = 3.5
## Determines how fast does the head tilt to its desired angle
@export var stilt_speed: float = 3.5


## The relative mouse rotation. Updated at every input and reset to 0 at every physics frame
var rotation: Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	# Mouse rotation
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotation.y = -event.relative.y * mouse_sensitivity_y
			rotation.x = -event.relative.x * mouse_sensitivity_x

func _physics_process(delta: float) -> void:
	_update_strafe_tilt(delta)
	_handle_mouse_rotation(delta)

func _update_strafe_tilt(delta: float) -> void:
	if !controller || !controller.head || !strafe_tilt_enabled: return
	var target_angle = max_stilt_angle*get_strafing_axis()
	controller.head.rotation_degrees.z = lerp(controller.head.rotation_degrees.z, target_angle, delta*stilt_speed)


func _handle_mouse_rotation(delta: float) -> void:
	# Early return for incorrect setup
	if !CORRECT_SETUP: return
	# Get desired yaw (L/R)
	var yaw_angle : float = rotation.x * delta
	# Get pitch angle (U/D)
	var pitch_angle : float = controller.head.rotation.x + (rotation.y * delta)
	# Limit pitch angle
	pitch_angle = clamp(pitch_angle, -deg_to_rad(max_vertical_angle), deg_to_rad(max_vertical_angle))
	
	# Apply yaw rotation using up vector
	controller.global_transform.basis = controller.global_transform.basis.rotated(controller.up_direction, yaw_angle)
	# Apply pitch rotation
	controller.head.rotation.x = pitch_angle
	
	# After using the rotation vector, flush it so that it doesn't keep rotating after an initial input
	rotation = Vector2.ZERO

func get_strafing_axis() -> float:
	return Input.get_axis("move_right", "move_left")
