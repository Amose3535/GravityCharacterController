extends CharacterBody3D



const JUMP_VELOCITY = 4.5


@warning_ignore("shadowed_variable_base_class")
## Variable responsible for retrieving the state with respect to the ground of the player. Returns false if accessed before ground_ray is initialized
var target_gravity_direction : Vector3 = Vector3.DOWN

## The direction that gravity is applied
@onready var gravity_direction : Vector3 = Vector3.DOWN:
	set(new_dir):
		gravity_direction = new_dir.normalized()
		up_direction = gravity_direction

## Gravity strength ( by default 9.807 )
@export var gravity : float = 9.807
## The length of the raycast pointing towards the feet of the character
@export var ground_ray_length : float = 0.1
## The collision shape of the player. If none is set, the script will try to get the first child node of type CollisionShape3D
@export var collision_shape : CollisionShape3D = null
## The speed at which the gravity will change towards the desired direction
@export var align_speed : float = 1.0
## The movement speed of the player
@export var speed: float = 5.0
## How fast you reach speed
@export var accel: float = 40
## How fast you stop
@export var decel: float = 30.0
## The camera node
@export var camera : Camera3D = null

var captured : bool = false

func _ready() -> void:
	# First setup the collision shape
	_setup_collision_shape()
	toggle_mouse_mode() # capture mouse


func _physics_process(delta: float) -> void:
	# Slowly align gravity dir towards target
	gravity_direction = gravity_direction.slerp(target_gravity_direction.normalized(), min(1.0, align_speed * delta)).normalized()
	#print("Gravity direction: ",gravity_direction)
	
	# Get input Vector (on 2D plane perpendicular to y axis)
	var input_dir : Vector2 = get_input_vector()
	
	var forward : Vector3 = -global_transform.basis.z
	var right : Vector3 = global_transform.basis.x
	
	# Project onto plane orthogonal to gravity direction with length 1
	forward = project_on_plane(forward, gravity_direction).normalized()
	right = project_on_plane(right, gravity_direction).normalized()
	
	# Final movement direction
	var move_dir : Vector3 = (forward * input_dir.y + right * input_dir.x)
	if move_dir.length() > 1.0:
		move_dir = move_dir.normalized()
	
	var tangent: Vector3 = velocity - velocity.project(gravity_direction)
	var target_tangent: Vector3 = move_dir * speed
	var rate: float = accel if (move_dir.length() > 0.0) else decel
	tangent = tangent.move_toward(target_tangent, rate * delta)
	velocity = tangent + velocity.project(gravity_direction)
	
	
	# if not on floor, add gravity
	if !is_on_floor():
		print("ISN'T ON FLOOR | Up : %s, Crrent : %s")
		velocity += gravity_direction * gravity * delta
	
	# If on floor and is jumping, apply jump towards UP vector (- gravity direction)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity += up_direction * JUMP_VELOCITY
	
	
	
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			toggle_mouse_mode()

func toggle_mouse_mode() -> void:
	if captured:
		captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _setup_collision_shape() -> void:
	# Setup collision_shape
	if !collision_shape:
		var collision_candidates : Array[Node] = get_children()
		# Try to get the first CollisionShape3D
		for collision_candidate in collision_candidates:
			if collision_candidate != null and collision_candidate is CollisionShape3D:
				collision_shape = collision_candidate
				break

func _align_to_gravity(delta: float) -> void:
	var up := -gravity_direction
	var forward := -global_transform.basis.z
	
	# Project forward on the plane tanget to the new gravity (prevents roll)
	var forward_proj := forward - up * forward.dot(up)
	if forward_proj.length() < 0.001:
		forward_proj = Vector3.FORWARD
	else:
		forward_proj = forward_proj.normalized()
	
	var right := up.cross(forward_proj).normalized()
	var target_basis := Basis(right, up, -forward_proj)
	
	# Interpolate for a smooth effect
	global_transform.basis = global_transform.basis.slerp(target_basis, align_speed * delta)

func get_input_vector() -> Vector2:
	var input_dir = Vector2(
	Input.get_action_raw_strength("move_right") - Input.get_action_raw_strength("move_left"),
	Input.get_action_raw_strength("move_forward") - Input.get_action_raw_strength("move_backward")
	)
	return input_dir


func project_on_plane(v: Vector3, n: Vector3) -> Vector3:
	return v - n * v.dot(n)
