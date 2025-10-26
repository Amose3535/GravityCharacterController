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


func _unhandled_input(event: InputEvent) -> void:
	# Mouse rotation
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			_handle_mouse_rotation(event)


func _handle_mouse_rotation(event: InputEventMouseMotion) -> void:
	# Early return for incorrect setup
	if !CORRECT_SETUP: return
	# 1. Rotazione del Corpo (Yaw) - Attorno all'asse UP (Pitch fisso)
	# Ruota il CharacterBody3D attorno al suo asse UP (-gravity_direction)
	var yaw_angle : float = -event.relative.x * mouse_sensitivity_x
	
	# Applichiamo la rotazione usando l'asse UP (gravità)
	# Nota: L'uso di global_transform.basis.rotated() è robusto con la gravità
	controller.global_transform.basis = controller.global_transform.basis.rotated(controller.up_direction, yaw_angle)
	
	# 2. Rotazione della Testa (Pitch) - Guardare su/giù
	# Ruota il nodo head attorno al suo asse X locale.
	var pitch_angle : float = -event.relative.y * mouse_sensitivity_y
	
	# Calcoliamo la rotazione finale desiderata
	var new_pitch : float = controller.head.rotation.x + pitch_angle
	
	# Limitiamo la rotazione (in radianti)
	var max_angle_rad : float = deg_to_rad(max_vertical_angle)
	new_pitch = clamp(new_pitch, -max_angle_rad, max_angle_rad)
	
	# Applichiamo la rotazione alla testa/camera (solo sull'asse X)
	controller.head.rotation.x = new_pitch
