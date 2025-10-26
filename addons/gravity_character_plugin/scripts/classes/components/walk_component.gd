extends BaseComponent
class_name WalkComponent

@export_group("Controls")
## Toggle sprint or not
@export var toggle_sprint : bool = false

@export_group("Movement")
## The movement speed of the player
@export var speed: float = 8.0
## The sprint multiplier
@export var sprint_multiplier : float = 2.0
## How fast you reach speed
@export var accel: float = 45.0
## How fast you stop
@export var decel: float = 45.0


## Wether the player is sprinting.
var sprinting : bool = false


func _ready() -> void:
	if !component_name or component_name == "":
		component_name = "walk_component"

func _physics_process(delta: float) -> void:
	# Movement related functions
	_move_perpendicularly_to_gravity(delta)

func _move_perpendicularly_to_gravity(delta : float) -> void:
	var move_dir = get_movement()
	
	var tangent: Vector3 = controller.velocity - controller.velocity.project(controller.gravity_direction)
	var target_tangent: Vector3 = (move_dir * speed * sprint_multiplier) if sprinting else (move_dir * speed)
	var rate: float = accel if (move_dir.length() > 0.0) else decel
	tangent = tangent.move_toward(target_tangent, rate * delta)
	controller.velocity = tangent + controller.velocity.project(controller.gravity_direction)
	
	_update_sprint_state()

func _update_sprint_state() -> void:
	# 1. Gestione Hold (Tasto Premuto)
	if !toggle_sprint:
		sprinting = Input.is_action_pressed("sprint")
		return
	
	# 2. Gestione Toggle (Cambio Stato)
	if Input.is_action_just_pressed("sprint"):
		# Inverti lo stato di sprint
		sprinting = !sprinting
	
	# Aggiunta opzionale: Disattiva lo sprint in toggle se si rilascia il movimento
	# Questo migliora la sensazione di gioco: lo sprint dovrebbe interrompersi quando ci si ferma.
	var input_movement_active = get_input_vector().length_squared() > 0.05
	if sprinting and !input_movement_active:
		sprinting = false

func get_movement() -> Vector3:
	# Get input Vector (on 2D plane perpendicular to y axis)
	var input_dir : Vector2 = get_input_vector()
	
	var forward : Vector3 = -controller.global_transform.basis.z
	var right : Vector3 = controller.global_transform.basis.x
	
	# Project onto plane orthogonal to gravity direction with length 1
	forward = controller.project_on_plane(forward, controller.gravity_direction).normalized()
	right = controller.project_on_plane(right, controller.gravity_direction).normalized()
	
	# Final movement direction
	var move_dir : Vector3 = (forward * input_dir.y + right * input_dir.x)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()
	
	return move_dir

## Returns a Vector2 containing the horizontal input direction of the player.
func get_input_vector() -> Vector2:
	var input_dir = Vector2(
	Input.get_axis("move_left","move_right"),
	Input.get_axis("move_backward","move_forward")
	)
	return input_dir
