extends CharacterBody3D
class_name GravityCharacter3D





## The direction that gravity is applied
@onready var gravity_direction : Vector3 = Vector3.DOWN:
	set(new_dir):
		if new_dir == Vector3.ZERO:
			return
		gravity_direction = new_dir.normalized()
		up_direction = -gravity_direction





#region EXPORTS
@export_group("Nodes")
## The head node. Can be a pivot for the camera and other nodes, the camera itself, or really anything that should be considered a "head"
@export var head : Node3D = null
## The CollisionShape3D. Not mandatory when using the default ground detection but it's necessary when using the custom ground detection (used to get the lowest point of the character)
@export var collision_shape : CollisionShape3D = null

@export_group("Parameters")
@export_subgroup("Gravity")
## Gravity strength ( by default 9.807 )
@export var gravity : float = 9.807
## The speed at which the body will rotate (with its feet DOWN) towards the desired direction
@export var align_speed : float = 100.0

@export_subgroup("Controls")
## Toggle sprint or not
@export var toggle_sprint : bool = false
## Toggles on or off constant jump height
@export var constant_jump : bool = false
## Wether to auto capture mouse at start
@export var auto_mouse_capture : bool = true
## Toggles wether to use built-in ground detection. If enabled it will probably be more efficient but will yield a worse result when rotating around spherical objects.
@export var default_ground_detection : bool = true
## Controls how long will the raycast used to check the ground coming out of the bottom of the CollisionShape3D of the character be.
@export_range(0.01,10.0,0.01,"or_greater") var ground_ray_length : float = 0.1
## Toggles wether to buffer the jump input if pressed just before landing (jump queue).
@export var jump_buffer_enabled : bool = true
## The maximum time the jump input will be buffered for (e.g., 0.1 seconds).
@export var jump_buffer_threshold : float = 0.1
## Toggles cooldown for gravity direction changes
@export var gravity_change_cooldown : bool = false
## How much time (in seconds) passes before the gravity can change again
@export var gravity_cooldown : float = 1.0


@export_subgroup("Movement")
## The initial vertical speed when jumping
@export var jump_strength : float = 6.0
## The movement speed of the player
@export var speed: float = 5.0
## The sprint multiplier
@export var sprint_multiplier : float = 1.5
## How fast you reach speed
@export var accel: float = 40.0
## How fast you stop
@export var decel: float = 30.0


@export_group("Rotation")
## Sensitivity for the mouse/analog stick X axis (Yaw)
@export var mouse_sensitivity_x : float = 0.002
## Sensitivity for the mouse/analog stick Y axis (Pitch)
@export var mouse_sensitivity_y : float = 0.002
## Maximum vertical angle for the head rotation (in degrees)
@export var max_vertical_angle : float = 85.0


@export_group("Settings")
## Wether rotation around the vertical axis for the body of the player or the 
@export var view_mode : ViewMode = ViewMode.FIRST_PERSON
#endregion EXPORTS





#region VARIABLES
## The state of the mouse
var mouse_captured : bool = false
## last time since touching ground
var last_ground_contact : float = 0.0
## Stores the remaining time for the jump input buffer (how long ago jump was pressed).
var jump_buffer_timer : float = 0.0 
## Time passed since the last gravity change (used for cooldown).
var last_gravity_change : float = 0.0
## Wether was the jump button released or not
var jumping : bool = false
## Wether the player is sprinting.
var sprinting : bool = false
## The raycast used when overriding the default is_on_floor() function
var ground_raycast : RayCast3D = null
## The variable used to update state of the raycast. Returns false when the default detection is on or when the ground raycast isn't initialized
var on_floor : bool = false:
	get:
		var ret_val : bool = false
		if !default_ground_detection and ground_raycast:
			ret_val = ground_raycast.is_colliding()
		return ret_val
## Enum for view mode
enum ViewMode {
	## In first person, the rotation of the body and the head is determined by the rotation axis (extracted via mouse or analog stick)
	FIRST_PERSON,
	## In third person, the rotation for the body and the head is determined by the movement direction
	THIRD_PERSON
}
#endregion VARIABLES





func _ready() -> void:
	# First setup the collision shape
	_setup_head()
	if auto_mouse_capture:
		toggle_mouse_mode() # capture mouse
	if !default_ground_detection:
		_setup_collision_shape()
		_setup_raycast()

func _physics_process(delta: float) -> void:
	_update_jump_buffer(delta)
	
	_handle_rotation(delta)
	
	_update_sprint_state()
	
	_move_perpendicularly_to_gravity(delta)
	
	_handle_jump()
	
	_update_last_gravity_change(delta)
	
	_apply_gravity(delta)
	
	_apply_ground_snapping(delta)
	
	_align_with_gravity(delta)
	
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			toggle_mouse_mode()
	
	# Mouse rotation
	if view_mode == ViewMode.FIRST_PERSON and mouse_captured:
		if event is InputEventMouseMotion:
			_handle_mouse_rotation(event)


#region CUSTOM FUNCTIONS
func toggle_mouse_mode() -> void:
	if mouse_captured:
		mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _setup_head() -> void:
	# Setup head only if the head export parameter is missing
	if !head:
		var head_candidates : Array[Node] = get_children()
		# Try to get the first Head 
		for head_candidate in head_candidates:
			if ((head_candidate != null) and (head_candidate is Node3D) and !(head_candidate is CollisionShape3D)):
				head = head_candidate
				break

func _setup_collision_shape() -> void:
	# Setup collision_shape only if the collision_shape export parameter is missing
	if !collision_shape:
		var collision_shape_candidates : Array[Node] = get_children()
		# Try to get the first Head 
		for collision_shape_candidate in collision_shape_candidates:
			if ((collision_shape_candidate != null) and (collision_shape_candidate is CollisionShape3D) and ((collision_shape_candidate.shape is CylinderShape3D) or (collision_shape_candidate.shape is CapsuleShape3D) or (collision_shape_candidate.shape is BoxShape3D) or (collision_shape_candidate.shape is SphereShape3D))):
				collision_shape = collision_shape_candidate
				break

func _setup_raycast() -> void:
	if collision_shape:
		var ray_offset : float = 0.0
		var shape : Shape3D = collision_shape.shape
		# Setup raycast offset
		if shape is CylinderShape3D or shape is CapsuleShape3D:
			ray_offset = shape.height/2
		if shape is BoxShape3D:
			ray_offset = (shape as BoxShape3D).size.y/2
		if shape is SphereShape3D:
			ray_offset = (shape as SphereShape3D).radius
		ground_raycast = RayCast3D.new()
		# Add raycast to player node
		add_child(ground_raycast,true,InternalMode.INTERNAL_MODE_BACK)
		# Set its position with the offset
		ground_raycast.position = collision_shape.position - up_direction*ray_offset
		# Set target position
		ground_raycast.target_position = -up_direction * ground_ray_length

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

func _handle_rotation(delta : float) -> void:
	# Verifichiamo che il nodo head esista prima di procedere
	if !head:
		return
	
	match view_mode:
		ViewMode.FIRST_PERSON:
			_handle_first_person_rotation()
		ViewMode.THIRD_PERSON:
			_handle_third_person_rotation(delta)

func _handle_first_person_rotation() -> void:
	# Rotazione in prima persona:
	# 1. Corpo (Yaw) ruota con il mouse/analogico orizzontale.
	# 2. Testa (Pitch) ruota con il mouse/analogico verticale.
	
	if mouse_captured:
		# Gestione input Raw mouse motion (se il mouse è catturato)
		# Nota: L'input del mouse viene gestito in _unhandled_input per la migliore performance,
		# ma per semplicità lo implementiamo qui usando Input.get_last_mouse_speed() o
		# delegando a una funzione apposita.
		
		# Solitamente si gestisce in _unhandled_input, ma per un esempio completo
		# e senza Eventi persi, useremo una variabile temporanea che dovrai aggiornare
		# in _unhandled_input(event: InputEventMouseMotion).
		
		# Visto che non abbiamo accesso diretto al delta del mouse in _physics_process,
		# modifichiamo l'approccio e gestiamo la rotazione YAW/PITCH tramite il mouse 
		# in _unhandled_input e chiamiamo una funzione di aggiornamento.
		pass # Lasciamo il corpo di questa funzione vuoto per ora e passiamo a _unhandled_input

func _handle_third_person_rotation(delta : float) -> void:
	# Rotazione in terza persona:
	# 1. Corpo (Yaw) si allinea alla direzione del movimento.
	# 2. Testa (Pitch) non si muove (o mantiene l'ultimo Pitch impostato).
	
	var movement_vector : Vector3 = get_movement()
	
	# Ruota il corpo solo se c'è un input di movimento significativo
	if movement_vector.length_squared() > 0.05:
		var target_basis : Basis = Basis.looking_at(movement_vector, up_direction)
		
		# Interpolazione lenta per una rotazione fluida (usiamo lo stesso align_speed)
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
	var is_currently_on_floor : bool = is_on_floor() if default_ground_detection else on_floor
	
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

func set_new_gravity_direction(new_dir: Vector3, force: bool = false) -> bool:
	
	# La gravità non cambia se la nuova direzione è identica alla corrente
	if new_dir.normalized().is_equal_approx(gravity_direction):
		return true
	
	# Controllo di override: se 'force' è true, procediamo immediatamente
	if force:
		gravity_direction = new_dir # Uses setter
		last_gravity_change = 0.0 # Reset del timer
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

func _update_last_gravity_change(delta : float) -> void:
	last_gravity_change += delta

func _apply_gravity(delta: float) -> void:
	if default_ground_detection:
		if !constant_jump:
			# if not on floor, add gravity
			if !is_on_floor():
				last_ground_contact += delta
				# If i'm still pressing the jump key, apply a different formula with respect to if i stop pressing the key early (controllable jump heights)
				if Input.is_action_pressed("jump"):
					# If i'm pressing the jump button but the jump variable isn't true, update it
					if !jumping:
						jumping = true
					# Apply the velocity along the gravity direction using the formula: g*t^2
					velocity += gravity_direction * gravity * last_ground_contact * last_ground_contact
				else:
					# If i'm supposedly jumping but i have released the jump key, set the jumping variable to false and divide the last contactby a 
					# certain value to fix the "slam" the character does if i release the jump key at the maximum height
					if jumping:
						jumping = false
						last_ground_contact /= 2
					# Apply the velocity along the gravity direction using the formula: g*t
					velocity += gravity_direction * gravity * last_ground_contact
			else:
				# Reset timer
				if last_ground_contact > 0:
					last_ground_contact = 0
				if jumping:
					jumping = false
		else:
			# if not on floor, add gravity
			if !is_on_floor():
				last_ground_contact += delta
				# Apply the velocity along the gravity direction using the formula: g*t
				velocity += gravity_direction * gravity * last_ground_contact
			else:
				# Reset timer
				if last_ground_contact > 0:
					last_ground_contact = 0
	else:
		if !constant_jump:
			# if not on floor, add gravity
			if !on_floor:
				last_ground_contact += delta
				# If i'm still pressing the jump key, apply a different formula with respect to if i stop pressing the key early (controllable jump heights)
				if Input.is_action_pressed("jump"):
					# If i'm pressing the jump button but the jump variable isn't true, update it
					if !jumping:
						jumping = true
					# Apply the velocity along the gravity direction using the formula: g*t^2
					velocity += gravity_direction * gravity * last_ground_contact * last_ground_contact
				else:
					# If i'm supposedly jumping but i have released the jump key, set the jumping variable to false and divide the last contactby a 
					# certain value to fix the "slam" the character does if i release the jump key at the maximum height
					if jumping:
						jumping = false
						last_ground_contact /= 2
					# Apply the velocity along the gravity direction using the formula: g*t
					velocity += gravity_direction * gravity * last_ground_contact
			else:
				# Reset timer
				if last_ground_contact > 0:
					last_ground_contact = 0
				if jumping:
					jumping = false
		else:
			# if not on floor, add gravity
			if !on_floor:
				last_ground_contact += delta
				# Apply the velocity along the gravity direction using the formula: g*t
				velocity += gravity_direction * gravity * last_ground_contact
			else:
				# Reset timer
				if last_ground_contact > 0:
					last_ground_contact = 0

func _apply_ground_snapping(delta : float) -> void:
	# Eseguiamo lo snapping SOLO se usiamo la ground detection customizzata
	if default_ground_detection || !ground_raycast:
		return
	
	# Solo se siamo a terra (o quasi), applichiamo lo snapping.
	# Non vogliamo fare snapping quando siamo in caduta libera o stiamo saltando.
	if on_floor:
		# Otteniamo i dati di collisione
		var collider = ground_raycast.get_collider()
		var collision_normal = ground_raycast.get_collision_normal()
		
		# Verifichiamo che il raycast abbia fornito dati validi
		if collider != null:
			# Metodo più sicuro e meno invasivo:
			# Spingiamo leggermente il player verso il basso lungo la NORMALE
			var snap_down : Vector3 = -collision_normal * ground_ray_length * 2.0 * get_physics_process_delta_time() * delta
			velocity += snap_down

func _align_with_gravity(delta: float) -> void:
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

func get_input_vector() -> Vector2:
	var input_dir = Vector2(
	Input.get_axis("move_left","move_right"),
	Input.get_axis("move_backward","move_forward")
	)
	return input_dir

func project_on_plane(v: Vector3, n: Vector3) -> Vector3:
	return v - n * v.dot(n)
#endregion CUSTOM FUNCTIONS
