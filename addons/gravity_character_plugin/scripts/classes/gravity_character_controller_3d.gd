# gravity_character_controller_3d.gd
extends GravityCharacter3D
class_name GravityController3D
## An implementation of GravityCharacter3D that supports rotation matching the gravity vector. And mouse / JoyPad rotation


@export_group("Setup")
## The head node. Can be a pivot for the camera and other nodes, the camera itself, or really anything that should be considered a "head"
@export var head : Node3D = null
## The collision shape. Not necessary but if provided can reduce computations needed by child nodes/component nodes
@export var collision_shape : CollisionShape3D = null
## The ComponentContainer node. Not necessary but useful when making a complex character component. It's to be considered as mandatory when using the premade components
@export var component_container : ComponentContainer = null

@export_group("Gravity related")
## The speed at which the body will rotate (with its feet DOWN) towards the desired direction
@export var align_speed : float = 5.0
## Toggles cooldown for gravity direction changes
@export var gravity_change_cooldown : bool = false
## How much time (in seconds) passes before the gravity can change again
@export var gravity_cooldown : float = 1.0



## Time passed since the last gravity change (used for cooldown).
var last_gravity_change : float = 0.0


var last_ground_contact : float = 0

func _ready() -> void:
	_setup_collision_shape()

func _physics_process(delta: float) -> void:
	# Gravity related functions
	_align_controller_with_gravity(delta)
	_update_last_gravity_change(delta)
	_apply_gravity(delta)
	#_debug_last_ground_contact(delta)
	move_and_slide() # Move and slide function. Preferred over move_and_collide()


func _setup_collision_shape() -> void:
	# Setup collision_shape only if the collision_shape export parameter is missing
	if !collision_shape:
		var collision_shape_candidates : Array[Node] = get_children()
		# Try to get the first Head 
		for collision_shape_candidate in collision_shape_candidates:
			if ((collision_shape_candidate != null) and (collision_shape_candidate is CollisionShape3D) and ((collision_shape_candidate.shape is CylinderShape3D) or (collision_shape_candidate.shape is CapsuleShape3D) or (collision_shape_candidate.shape is BoxShape3D) or (collision_shape_candidate.shape is SphereShape3D))):
				collision_shape = collision_shape_candidate
				break

#region GRAVITY FUNCTIONS (CORE)
## Increments the last change of gravity by delta
func _update_last_gravity_change(delta : float) -> void:
	last_gravity_change += delta

## API used to align the player's rotation along the gravity's direction using what it's looking at (it's more natual since it follows the look/rotation)
func _align_controller_with_gravity(delta: float) -> void:
	# 1. Calcola l'allineamento verticale (Roll e Pitch)
	
	# La nuova base deve avere 'up_direction' come asse Y.
	# Il modo migliore per calcolarla è con 'Basis.looking_at'.
	
	# Usiamo la direzione 'forward' della telecamera (o del CharacterBody) ma 
	# la proiettiamo sul piano perpendicolare alla nuova gravità.
	
	# Direzione 'forward' attuale (libera da roll/pitch indesiderati)
	# Manteniamo la componente 'Yaw' (rotazione orizzontale) della telecamera.
	var camera_forward_dir : Vector3 = -head.global_transform.basis.z
	
	# Proiettiamo la direzione della telecamera sul piano del nuovo "pavimento" (Gravity-Aligned Plane)
	var desired_forward : Vector3 = GravityController3D.project_on_plane(camera_forward_dir, up_direction).normalized()
	
	# Se il vettore è zero (ad esempio, se la head guarda perfettamente in basso/alto),
	# usiamo il forward attuale del player per evitare un bug di 'looking_at'.
	if desired_forward.length_squared() < 0.0001:
		desired_forward = GravityController3D.project_on_plane(-global_transform.basis.z, up_direction).normalized()
	
	# Calcola la base desiderata: guarda 'desired_forward' con 'up_direction' come 'su'
	var target_basis : Basis = Basis.looking_at(desired_forward, up_direction)
	
	# 2. Interpolazione (rotazione graduale)
	global_transform.basis = global_transform.basis.slerp(target_basis, align_speed * delta)

## API used to wrap the gravity_direction setter with support for cooldown etc.
func set_new_gravity_direction(new_dir: Vector3, force: bool = !gravity_change_cooldown) -> bool:
	
	# La gravità non cambia se la nuova direzione è identica alla corrente
	if new_dir.normalized().is_equal_approx(gravity_direction):
		return true
	
	# Controllo di override: se 'force' è true, procediamo immediatamente
	if force:
		gravity_direction = new_dir # Uses setter
		return true
	
	# Gestione del Cooldown:
	if gravity_change_cooldown:
		if last_gravity_change < gravity_cooldown:
			# Ancora in cooldown
			return false
	
	# Cooldown non attivo O Cooldown completato:
	gravity_direction = new_dir # Uses setter
	last_gravity_change = 0.0 # Reset del timer
	return true

func _apply_gravity(delta: float) -> void:
	# Not airborne
	if is_on_floor():
		return
	# Constant jump height: g * t
	velocity += gravity_direction * gravity * delta

func _debug_last_ground_contact(delta : float) -> void:
	if !is_on_floor():
		last_ground_contact += delta
		print(last_ground_contact)
	else:
		last_ground_contact = 0
#endregion GRAVITY

## Returns a Vector2 containing the horizontal input direction of the player.
func get_input_vector() -> Vector2:
	var input_dir = Vector2(
	Input.get_axis("move_left","move_right"),
	Input.get_axis("move_backward","move_forward")
	)
	return input_dir

func get_statemachine_if_present() -> ComponentStateMachine:
	var children = get_children()
	var ret_child : ComponentStateMachine = null
	for child in children:
		if child is ComponentStateMachine:
			ret_child = child 
	return ret_child
