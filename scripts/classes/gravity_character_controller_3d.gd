# gravity_character_controller_3d.gd
extends GravityCharacter3D
class_name GravityController3D
## An implementation of GravityCharacter3D that supports rotation matching the gravity vector. And mouse / JoyPad rotation




## The CollisionShape3D. Not mandatory when using the default ground detection but it's necessary when using the custom ground detection (used to get the lowest point of the character)


@export_group("Nodes")
## The head node. Can be a pivot for the camera and other nodes, the camera itself, or really anything that should be considered a "head"
@export var head : Node3D = null
@export var collision_shape : CollisionShape3D = null

@export_group("Gravity")
## The speed at which the body will rotate (with its feet DOWN) towards the desired direction
@export var align_speed : float = 5.0
## Toggles cooldown for gravity direction changes
@export var gravity_change_cooldown : bool = false
## How much time (in seconds) passes before the gravity can change again
@export var gravity_cooldown : float = 1.0

@export_group("Controls")
## Toggle sprint or not
@export var toggle_sprint : bool = false
## Toggles on or off constant jump height
@export var constant_jump : bool = false
## Wether to auto capture mouse at start
@export var auto_mouse_capture : bool = true
## Toggles wether to buffer the jump input if pressed just before landing (jump queue).
@export var jump_buffer_enabled : bool = true
## The maximum time the jump input will be buffered for (e.g., 0.1 seconds).
@export var jump_buffer_threshold : float = 0.1

@export_group("Movement")
## The initial vertical speed when jumping
@export var jump_strength : float = 6.0
## The movement speed of the player
@export var speed: float = 8.0
## The sprint multiplier
@export var sprint_multiplier : float = 2.0
## How fast you reach speed
@export var accel: float = 45.0
## How fast you stop
@export var decel: float = 45.0


@export_group("Rotation")
## Sensitivity for the mouse/analog stick X axis (Yaw)
@export_range(0.0, 1.0, 0.0001) var mouse_sensitivity_x : float = 0.002
## Sensitivity for the mouse/analog stick Y axis (Pitch)
@export_range(0.0, 1.0, 0.0001) var mouse_sensitivity_y : float = 0.002
## Maximum vertical angle for the head rotation (in degrees)
@export_range(0.1, 89.9, 0.100) var max_vertical_angle : float = 89.9


@export_group("Settings")
## Wether rotation around the vertical axis for the body of the player or the 
@export var view_mode : ViewMode = ViewMode.FIRST_PERSON
## The third person camera. Only used when GravityCharacter3D.view_mode is set to ViewMode.THIRD_PERSON
@export var third_person_camera : Camera3D = null
## Determines wether to reset the timer that measures the last_ground_contact upon gravity change
@export var reset_attraction_on_gravity_change : bool = true


## The state of the mouse
var mouse_captured : bool = false
## Wether was the jump button released or not
var jumping : bool = false
## Stores the remaining time for the jump input buffer (how long ago jump was pressed).
var jump_buffer_timer : float = 0.0 
## Wether the player is sprinting.
var sprinting : bool = false
## Enum for view mode
enum ViewMode {
	## In first person, the rotation of the body and the head is determined by the rotation axis (extracted via mouse or analog stick)
	FIRST_PERSON,
	## In third person, the rotation for the body and the head is determined by the movement direction
	THIRD_PERSON
}
## last time since touching ground (commonly used for gravity)
var last_ground_contact : float = 0.0
## Time passed since the last gravity change (used for cooldown).
var last_gravity_change : float = 0.0

func _ready() -> void:
	if auto_mouse_capture:
		toggle_mouse_mode() # capture mouse
	_setup_collision_shape()
	if view_mode == ViewMode.THIRD_PERSON:
		_setup_third_person()

func _physics_process(delta: float) -> void:
	_update_jump_buffer(delta)
	_update_sprint_state()
	_update_last_gravity_change(delta)
	
	_move_perpendicularly_to_gravity(delta)
	_handle_jump()
	_apply_gravity(delta)
	
	align_look_with_gravity(delta)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			toggle_mouse_mode()
	
	# Mouse rotation
	if view_mode == ViewMode.FIRST_PERSON and mouse_captured:
		if event is InputEventMouseMotion:
			_handle_mouse_rotation(event)

func _on_gravity_changed(from: Vector3, to: Vector3) -> void:
	if reset_attraction_on_gravity_change:
		last_ground_contact = 0


#region CUSTOM FUNCTIONS
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

func toggle_mouse_mode() -> void:
	if mouse_captured:
		mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _setup_collision_shape() -> void:
	# Setup collision_shape only if the collision_shape export parameter is missing
	if !collision_shape:
		var collision_shape_candidates : Array[Node] = get_children()
		# Try to get the first Head 
		for collision_shape_candidate in collision_shape_candidates:
			if ((collision_shape_candidate != null) and (collision_shape_candidate is CollisionShape3D) and ((collision_shape_candidate.shape is CylinderShape3D) or (collision_shape_candidate.shape is CapsuleShape3D) or (collision_shape_candidate.shape is BoxShape3D) or (collision_shape_candidate.shape is SphereShape3D))):
				collision_shape = collision_shape_candidate
				break

func _setup_third_person() -> void:
	if third_person_camera:
		var forward_z = third_person_camera.global_transform.basis.z.normalized()
		
		var right_x = up_direction.cross(forward_z).normalized()
		var forward = up_direction.cross(right_x).normalized()
		
		global_transform.basis = Basis(right_x, up_direction, -forward).orthonormalized()

func _update_jump_buffer(delta: float) -> void:
	if !jump_buffer_enabled:
		jump_buffer_timer = 0.0 # Resetta se disabilitato
		return
	
	# Se l'input è premuto O il timer è ancora attivo...
	if Input.is_action_just_pressed("jump"):
		# Inizializza il timer al massimo quando il tasto è premuto
		jump_buffer_timer = jump_buffer_threshold
	elif jump_buffer_timer > 0.0:
		# Se l'input NON è premuto, ma il timer è attivo, decrementa
		jump_buffer_timer -= delta

func _move_perpendicularly_to_gravity(delta : float) -> void:
	var move_dir = get_movement()
	
	var tangent: Vector3 = velocity - velocity.project(gravity_direction)
	var target_tangent: Vector3 = (move_dir * speed * sprint_multiplier) if sprinting else (move_dir * speed)
	var rate: float = accel if (move_dir.length() > 0.0) else decel
	tangent = tangent.move_toward(target_tangent, rate * delta)
	velocity = tangent + velocity.project(gravity_direction)

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

func _update_last_gravity_change(delta : float) -> void:
	last_gravity_change += delta

func _handle_mouse_rotation(event: InputEventMouseMotion) -> void:
	# 1. Rotazione del Corpo (Yaw) - Attorno all'asse UP (Pitch fisso)
	# Ruota il CharacterBody3D attorno al suo asse UP (-gravity_direction)
	var yaw_angle : float = -event.relative.x * mouse_sensitivity_x
	
	# Applichiamo la rotazione usando l'asse UP (gravità)
	# Nota: L'uso di global_transform.basis.rotated() è robusto con la gravità
	global_transform.basis = global_transform.basis.rotated(up_direction, yaw_angle)
	
	# 2. Rotazione della Testa (Pitch) - Guardare su/giù
	# Ruota il nodo head attorno al suo asse X locale.
	var pitch_angle : float = -event.relative.y * mouse_sensitivity_y
	
	# Calcoliamo la rotazione finale desiderata
	var new_pitch : float = head.rotation.x + pitch_angle
	
	# Limitiamo la rotazione (in radianti)
	var max_angle_rad : float = deg_to_rad(max_vertical_angle)
	new_pitch = clamp(new_pitch, -max_angle_rad, max_angle_rad)
	
	# Applichiamo la rotazione alla testa/camera (solo sull'asse X)
	head.rotation.x = new_pitch

func _handle_third_person_rotation(delta : float) -> void:
	# Rotazione in terza persona:
	# 1. Corpo (Yaw) si allinea alla direzione del movimento.
	# 2. Testa (Pitch) non si muove (o mantiene l'ultimo Pitch impostato).
	
	var movement_vector : Vector3 = get_movement()
	
	# Ruota il corpo solo se c'è un input di movimento significativo
	if movement_vector.length_squared() > 0.05:
		var target_basis : Basis = Basis.looking_at(movement_vector, up_direction)
		
		# Interpolazione lenta per una rotazione fluida (usiamo lo stesso align_speed)
		#global_transform.basis = global_transform.basis.slerp(target_basis, align_speed * delta)

## API used to align the player's rotation along the gravity's direction using what it's looking at (it's more natual since it follows the look/rotation)
func align_look_with_gravity(delta: float) -> void:
	# 1. Calcola l'allineamento verticale (Roll e Pitch)
	
	# La nuova base deve avere 'up_direction' come asse Y.
	# Il modo migliore per calcolarla è con 'Basis.looking_at'.
	
	# Usiamo la direzione 'forward' della telecamera (o del CharacterBody) ma 
	# la proiettiamo sul piano perpendicolare alla nuova gravità.
	
	# Direzione 'forward' attuale (libera da roll/pitch indesiderati)
	# Manteniamo la componente 'Yaw' (rotazione orizzontale) della telecamera.
	var camera_forward_dir : Vector3 = -head.global_transform.basis.z
	
	# Proiettiamo la direzione della telecamera sul piano del nuovo "pavimento" (Gravity-Aligned Plane)
	var desired_forward : Vector3 = project_on_plane(camera_forward_dir, up_direction).normalized()
	
	# Se il vettore è zero (ad esempio, se la head guarda perfettamente in basso/alto),
	# usiamo il forward attuale del player per evitare un bug di 'looking_at'.
	if desired_forward.length_squared() < 0.0001:
		desired_forward = project_on_plane(-global_transform.basis.z, up_direction).normalized()

	# Calcola la base desiderata: guarda 'desired_forward' con 'up_direction' come 'su'
	var target_basis : Basis = Basis.looking_at(desired_forward, up_direction)

	# 2. Interpolazione (rotazione graduale)
	global_transform.basis = global_transform.basis.slerp(target_basis, align_speed * delta)

##API used to align the player's rotation along the gravity's direction using its forward direction (less natural but not head-dependant)
func align_body_with_gravity(delta: float) -> void:
	# Proiettiamo la direzione della telecamera sul piano del nuovo "pavimento" (Gravity-Aligned Plane)
	var desired_forward : Vector3 = project_on_plane(-global_transform.basis.z, up_direction).normalized()

	# Calcola la base desiderata: guarda 'desired_forward' con 'up_direction' come 'su'
	var target_basis : Basis = Basis.looking_at(desired_forward, up_direction)

	# 2. Interpolazione (rotazione graduale)
	global_transform.basis = global_transform.basis.slerp(target_basis, align_speed * delta)

func get_movement() -> Vector3:
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
	
	return move_dir

func _handle_jump() -> void:
	# Determina se il personaggio è a terra, usando la logica di ground detection attiva.
	var is_currently_on_floor : bool = is_on_floor()
	
	var jump_requested : bool = Input.is_action_just_pressed("jump")
	var jump_buffered : bool = jump_buffer_enabled and jump_buffer_timer > 0.0
	var should_jump : bool = false
	
	# Condizione di Salto 1: Tasto premuto mentre si è a terra (Salto Immediato)
	if jump_requested and is_currently_on_floor:
		should_jump = true
		
	# Condizione di Salto 2: Buffer Attivo e Tocco a Terra (Salto in Coda)
	# Dobbiamo evitare di eseguire il buffer se si è già saltato per l'Input Immediato.
	elif jump_buffered and is_currently_on_floor:
		should_jump = true
		jump_buffer_timer = 0.0 # Consuma l'input nel buffer
	
	# Se l'input è premuto MA NON siamo a terra e il buffer è attivo, non facciamo nulla.
	# Il timer decrementerà o è già stato impostato in _update_jump_buffer.
	
	if should_jump:
		velocity += up_direction * jump_strength
		
		# IMPORTANTE: Resetta il contatto a terra per evitare bug di gravità nel frame successivo.
		last_ground_contact = 0.0

func _apply_gravity(delta: float) -> void:
	var grounded := is_on_floor()
	
	# Not airborne
	if grounded:
		if last_ground_contact > 0.0:
			last_ground_contact = 0.0
		if jumping:
			jumping = false
		return
	
	# Airborne
	last_ground_contact += delta
	
	if !constant_jump:
		if Input.is_action_pressed("jump"):
			if !jumping:
				jumping = true
			velocity += gravity_direction * gravity * delta
		else:
			if jumping:
				jumping = false
				last_ground_contact /= 2.0 # dampen strength by artificially halving the time it was airborne
			velocity += gravity_direction * 2*gravity * delta
	else:
		# Constant jump height: g * t
		velocity += gravity_direction * 2*gravity * delta

func get_input_vector() -> Vector2:
	var input_dir = Vector2(
	Input.get_axis("move_left","move_right"),
	Input.get_axis("move_backward","move_forward")
	)
	return input_dir

#endregion CUSTOM FUNCTIONS
