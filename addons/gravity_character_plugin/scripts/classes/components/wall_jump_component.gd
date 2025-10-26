extends BaseComponent
class_name WallJumpComponent
## A Component that allows the character to push off a vertical surface (wall jump).

#region EXPORTS
@export_group("Wall Jump")
## Horizontal strength applied away from the wall.
@export var push_strength_horizontal: float = 8.0 
## Vertical strength applied upwards during the jump.
@export var push_strength_vertical: float = 6.0 
## Distance the side raycasts extend to detect a wall.
@export var wall_check_distance: float = 0.35
## Time (in seconds) the character must wait between wall jumps (to prevent spam).
@export var wall_jump_cooldown: float = 0.5 
#endregion EXPORTS

#region VARIABLES
## RayCast used to detect the wall on the left side.
var left_raycast: RayCast3D = null
## RayCast used to detect the wall on the right side.
var right_raycast: RayCast3D = null
## Timer to track the time until the next wall jump is allowed.
var cooldown_timer: float = 0.0
#endregion VARIABLES

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	_setup_wall_raycasts()
	# Assicurati che WallJumpComponent si avvii disattivo se la FSM lo gestisce
	#if component_name != "": # Assume che se ha un nome, la FSM lo gestirà
		#active = false

func _physics_process(delta: float) -> void:
	# Aggiorna il cooldown
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	
	_handle_wall_jump()

## Configura e aggiunge i RayCast al nodo Head (o al Controller) per il rilevamento del muro.
func _setup_wall_raycasts() -> void:
	var ray_container = controller.head if controller.head else controller
	
	# La posizione iniziale dei RayCast deve essere a livello del centro del corpo
	var ray_start_position = Vector3.ZERO 
	
	# Crea RayCast Sinistro
	left_raycast = RayCast3D.new()
	left_raycast.name = "WallCheckLeft"
	ray_container.add_child(left_raycast)
	left_raycast.add_exception(controller)
	
	# Crea RayCast Destro
	right_raycast = RayCast3D.new()
	right_raycast.name = "WallCheckRight"
	ray_container.add_child(right_raycast)
	right_raycast.add_exception(controller)
	
	# Imposta l'orientamento: puntano in avanti, ma sono spostati ai lati
	# L'orientamento sarà gestito dalla rotazione del nodo Head
	left_raycast.position = ray_start_position
	right_raycast.position = ray_start_position
	
	# Il target punta in avanti
	left_raycast.target_position = Vector3(0, 0, -wall_check_distance) 
	right_raycast.target_position = Vector3(0, 0, -wall_check_distance)

## Controlla le condizioni e applica il Wall Jump se l'input è attivo.
func _handle_wall_jump() -> void:
	# Condizioni base: non a terra, cooldown non attivo, input salto premuto
	if controller.is_on_floor() || cooldown_timer > 0.0 || !Input.is_action_just_pressed("jump"):
		return
		
	var is_colliding_left = left_raycast.is_colliding()
	var is_colliding_right = right_raycast.is_colliding()
	
	if is_colliding_left || is_colliding_right:
		var collision_normal: Vector3
		
		# 1. Trova la normale del muro (usiamo la normale del RayCast che ha colpito)
		if is_colliding_left:
			collision_normal = left_raycast.get_collision_normal()
		elif is_colliding_right:
			collision_normal = right_raycast.get_collision_normal()
		
		# 2. Calcola lo spinta finale:
		
		# A) Spinta Orizzontale: Lontano dal muro (lungo la normale)
		var horizontal_push: Vector3 = collision_normal.normalized() * push_strength_horizontal
		
		# B) Spinta Verticale: Verso l'alto (lungo up_direction)
		var vertical_push: Vector3 = controller.up_direction * push_strength_vertical
		
		# 3. Applica la nuova velocity al controller:
		
		# Azzeriamo la velocity corrente per un salto pulito, mantenendo solo la nuova spinta.
		controller.velocity = horizontal_push + vertical_push
		
		# 4. Attiva il cooldown
		cooldown_timer = wall_jump_cooldown
		
		# [TODO: Emetti segnale 'wall_jumped' qui]
