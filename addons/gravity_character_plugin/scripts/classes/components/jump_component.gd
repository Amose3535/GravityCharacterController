extends BaseComponent
class_name JumpComponent
## A Component used to apply a vertical impulse upon input.


## The initial vertical speed when jumping
@export var jump_strength : float = 6.0
## Toggles wether to buffer the jump input if pressed just before landing (jump queue).
@export var jump_buffer_enabled : bool = true
## The maximum time the jump input will be buffered for (e.g., 0.1 seconds).
@export var jump_buffer_threshold : float = 0.1
## The maximum time AFTER leaving ground where i can request a jump (this implies i didn't already jump, otherwise coyote time just won't work)
@export var coyote_time : float = 0.3


## Stores the remaining time for the jump input buffer (how long ago jump was pressed).
var jump_buffer_timer : float = 0.0

# 🆕 VARIABILI COYOTE TIME
## Stores the remaining time for the coyote window (how long ago we left the ground).
var coyote_timer : float = 0.0
## Stores whether we successfully jumped during the current "jumpable" window (floor + coyote).
var has_jumped_since_leaving_ground : bool = false
# ----------------------------

func _ready() -> void:
	if !component_name or component_name == "":
		component_name = "jump_component"

func _physics_process(delta: float) -> void:
	# Jump related functions
	_update_jump_buffer(delta)
	_update_coyote_time(delta) # <--- NUOVA CHIAMATA
	_handle_jump()


## Gestisce il timer del coyote time (tempo trascorso da quando abbiamo lasciato il pavimento).
func _update_coyote_time(delta: float) -> void:
	var is_on_floor : bool = controller.is_on_floor()
	
	if is_on_floor:
		# 1. Se siamo a terra: Resetta lo stato di salto e inizializza il timer.
		coyote_timer = coyote_time # Inizializza al valore massimo
		has_jumped_since_leaving_ground = false
	elif coyote_timer > 0.0:
		# 2. Se siamo in aria E il timer è attivo: Decrementa.
		coyote_timer -= delta
	# Se coyote_timer <= 0.0, la finestra di perdono è chiusa.


func _handle_jump() -> void:
	# 1. Recupera lo stato attuale
	var jump_requested : bool = Input.is_action_just_pressed("jump")
	var jump_buffered : bool = jump_buffer_enabled and jump_buffer_timer > 0.0
	
	var should_jump : bool = false
	
	var is_in_coyote_window : bool = coyote_timer > 0.0
	var can_coyote_jump : bool = is_in_coyote_window and not has_jumped_since_leaving_ground
	
	# 2. SE SIAMO A TERRA: possiamo saltare immediatamente O usare il buffer
	#    OPPURE SE SIAMO NELLA FINESTRA DI COYOTE TIME E NON ABBIAMO GIA' SALTATO5
	if controller.is_on_floor() or can_coyote_jump: # <--- AGGIUNTA LA CONDIZIONE 'can_coyote_jump'
		# Salto Immediato (tasto premuto mentre a terra/coyote) O Salto in Coda (buffer attivo)
		if (jump_requested or jump_buffered) && ! Input.is_action_pressed("dash"):
			should_jump = true
			
	# 3. Esegui l'azione se necessario
	if should_jump:
		# Esegui il salto
		controller.velocity += controller.up_direction * jump_strength
		
		# ✅ CONSUMA IL BUFFER/TIMER OGNI VOLTA CHE UN SALTO È ESEGUITO
		jump_buffer_timer = 0.0
		# 🆕 REGISTRA IL SALTO E CONSUMA IL COYOTE TIME
		has_jumped_since_leaving_ground = true
		coyote_timer = 0.0 # Forza la chiusura della finestra di perdono


func _update_jump_buffer(delta: float) -> void:
	if !jump_buffer_enabled:
		jump_buffer_timer = 0.0
		return
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = jump_buffer_threshold
	elif jump_buffer_timer > 0.0:
		jump_buffer_timer -= delta
