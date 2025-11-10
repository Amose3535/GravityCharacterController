extends BaseComponent
class_name MovementComponent
## Class that handles movement

@export_group("Controls")
## Toggles sprint on or off
@export var can_sprint: bool = true
## Toggle sprint or not
@export var toggle_sprint : bool = true

@export_group("Movement")
## Allows to choose one type of movement from the available options
@export var movement_type: MovType = MovType.DEFAULT

## The movement speed of the player
@export var speed: float = 9.0
## The sprint multiplier
@export var sprint_multiplier : float = 1.9
## The wall multiplier
@export var wall_multiplier: float = 0.3
## How fast you reach speed
@export var accel: float = 45.0
## How fast you stop
@export var decel: float = 45.0
## The deceleration applied when you're on a wall
@export var wall_decel: float = 30.0
## How fast you reach speed in air
@export var airborne_accel: float = 15.0
## How fast you stop in air
@export var airborne_decel: float = 30.0
## The maximum angle before you slow down to the target tangent
@export var max_dir_angle: float = 15.0
## The max velocity needed to decelerate in air. If you go faster than the deadzone, you'll decelearate when using the default movement option
@export var velocity_deadzone: float = 12.0


## The enum containing the available movement options
enum MovType {
	## Default movement. A good balance between speed and control, good for various applications.
	DEFAULT,
	## A Quake-like movement. A nice mix of speed and control (leaning more on speed)
	QUAKE,
	OLD
}
## Wether the player is sprinting.
var sprinting : bool = false


func _ready() -> void:
	if !component_name or component_name == "":
		component_name = "movement_component"

func _physics_process(delta: float) -> void:
	# Movement related functions
	_move_perpendicularly_to_gravity(delta)

func _move_perpendicularly_to_gravity(delta : float) -> void:
	match movement_type:
		# Default movement
		MovType.DEFAULT:
			var move_dir = get_movement()
			controller.gravity_enabled = true
			
			# Tangent component is velocity perpendicular to gravity
			var tangent: Vector3 = controller.velocity - controller.velocity.project(controller.gravity_direction)
			
			# Calculate target speed (max speed allowed by input)
			var target_speed = speed * (sprint_multiplier if sprinting else 1) * (wall_multiplier if controller.is_on_wall_only() else 1)
			var target_tangent: Vector3 = move_dir * target_speed
			
			if controller.is_on_floor() || controller.is_on_wall():
				# === GROUND LOGIC (SHARED): Reach target speed, apply friction/decel ===
				
				# Sostituisci 'decel' con 'current_decel' se usi la logica scivolosa.
				var current_decel: float = wall_decel if controller.is_on_wall_only() else decel
				var rate = accel if (move_dir.length() > 0.0) else current_decel
				
				# Move velocity towards the target. Slows down excessive momentum.
				tangent = tangent.move_toward(target_tangent, rate * delta)
			else:
				if move_dir.length() > 0.001:
					# 1. Compute angle between tangent and input in degrees
					var angle_degrees = abs(rad_to_deg(get_angle_between_vectors(tangent, move_dir)))
					# If the angle is bigger than the max angle
					if angle_degrees > max_dir_angle:
						# Misaligned input (Frenata/Sterzata). Used move_toward to redirect velocity to the target, forcing deceleration if excessive (permettendo la frenata).
						tangent = tangent.move_toward(target_tangent, airborne_accel * delta)
						
					else:
						# 2. Input Allineato (Accelerazione/Guida)
						var added_velocity = move_dir * airborne_accel * delta
						
						# Limita l'accelerazione: solo se non siamo ancora al target_speed nella direzione di input
						var current_speed_in_input_dir = tangent.dot(move_dir.normalized())
						
						if current_speed_in_input_dir < target_speed:
							tangent += added_velocity
				else: # move_dir about 0
					if controller.get_horizontal_velocity().length() <= velocity_deadzone:
						tangent = tangent.move_toward(target_tangent, airborne_decel * delta)
					
			# Recombine the tangential (horizontal) and vertical (gravity) components
			controller.velocity = tangent + controller.velocity.project(controller.gravity_direction)
			
			_update_sprint_state()
		
		MovType.QUAKE:
			var move_dir: Vector3 = get_movement()
			controller.gravity_enabled = true
			
			var gravity_dir: Vector3 = controller.gravity_direction
			var vel = controller.velocity
			var tangent = vel - vel.project(gravity_dir)
			
			var wishdir: Vector3 = move_dir.normalized()
			var wishspeed: float = speed * (sprint_multiplier if sprinting else 1) * (wall_multiplier if controller.is_on_wall_only() else 1)
			
			if controller.is_on_floor() || controller.is_on_wall():
				# Ground movement (acceleration and deceleration)
				var rate: float = accel if move_dir.length() > 0.0 else decel
				var target_tangent: Vector3 = move_dir * speed * (sprint_multiplier if sprinting else 1) * (wall_multiplier if controller.is_on_wall_only() else 1)
				tangent = tangent.move_toward(target_tangent, rate * delta)
			else:
				# Air movement (NO deceleration if you don't contrast the movement)
				tangent = _accelerate_quake(tangent, wishdir, wishspeed, airborne_accel, delta)
				
			
			controller.velocity = tangent + vel.project(gravity_dir)
			_update_sprint_state()
		
		MovType.OLD:
			var move_dir = get_movement()
			controller.gravity_enabled = true
			var tangent: Vector3 = controller.velocity - controller.velocity.project(controller.gravity_direction)
			var target_tangent: Vector3 = move_dir * speed * (sprint_multiplier if sprinting else 1) * (wall_multiplier if controller.is_on_wall_only() else 1)
			var rate: float
			if controller.is_on_floor():
				rate = accel if (move_dir.length() > 0.0) else decel
			else:
				rate = airborne_accel if (move_dir.length() > 0.0) else airborne_decel
			tangent = tangent.move_toward(target_tangent, rate * delta)
			controller.velocity = tangent + controller.velocity.project(controller.gravity_direction)
			
			_update_sprint_state()


func _accelerate_quake(vel: Vector3, wishdir: Vector3, wishspeed: float, acceleration: float, delta: float) -> Vector3:
	if wishdir.length() == 0.0:
		return vel
	
	var currentspeed = vel.dot(wishdir)
	var addspeed = wishspeed - currentspeed
	if addspeed <= 0:
		return vel
	
	var accelspeed = acceleration * wishspeed * delta
	if accelspeed > addspeed:
		accelspeed = addspeed
	
	return vel + wishdir * accelspeed


func get_angle_between_vectors(vec_a: Vector3, vec_b: Vector3) -> float:
	# Normalize vectors
	var unit_a: Vector3 = vec_a.normalized()
	var unit_b: Vector3 = vec_b.normalized()
	# Compute dot product
	var dot_product: float = unit_a.dot(unit_b)
	# Clamp product between -1 and 1 in case of floating point errors
	dot_product = clamp(dot_product, -1.0, 1.0)
	# Use arccos to get angle in radians
	var angle_radians: float = acos(dot_product)
	return angle_radians


func get_angle_between_vectors_2d(vec_a: Vector2, vec_b: Vector2) -> float:
	# return angle between two vector2-s in radians
	return vec_a.angle_to(vec_b)

func _update_sprint_state() -> void:
	if !can_sprint: 
		sprinting = false
		return
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
	var input_movement_active = controller.get_input_vector().length_squared() > 0.05
	if sprinting and !input_movement_active:
		sprinting = false

func get_movement() -> Vector3:
	# Get input Vector (on 2D plane perpendicular to y axis)
	var input_dir : Vector2 = controller.get_input_vector()
	
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
