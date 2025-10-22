extends BaseComponent
class_name JumpComponent
## A Component used to apply a vertical impulse upon input.


## The initial vertical speed when jumping
@export var jump_strength : float = 6.0
## Toggles on or off constant jump height
@export var constant_jump : bool = false
## How much of the original velocity along the gravity direction should be removed each frame when pressing the jump key.
@export var variable_jump_dampening : float = 2
## Toggles wether to buffer the jump input if pressed just before landing (jump queue).
@export var jump_buffer_enabled : bool = true
## The maximum time the jump input will be buffered for (e.g., 0.1 seconds).
@export var jump_buffer_threshold : float = 0.1



## Stores the remaining time for the jump input buffer (how long ago jump was pressed).
var jump_buffer_timer : float = 0.0 

func _physics_process(delta: float) -> void:
	# Jump related functions
	_update_jump_buffer(delta)
	_handle_jump()
	_dampen_fall(delta) # Has an effect when constant_jump is disabled

func _handle_jump() -> void:
	# Determina se il personaggio è a terra, usando la logica di ground detection attiva.
	var is_currently_on_floor : bool = controller.is_on_floor()
	#print(is_currently_on_floor)
	
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
		controller.velocity += controller.up_direction * jump_strength

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

func _dampen_fall(delta : float) -> void:
	if !constant_jump and Input.is_action_pressed("jump"):
		controller.velocity -= (controller.gravity_direction * controller.gravity * delta)/3 # A third of the formula for gravity is dampened
