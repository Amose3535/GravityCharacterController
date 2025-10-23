extends BaseComponent
class_name JumpComponent
## A Component used to apply a vertical impulse upon input.


## The initial vertical speed when jumping
@export var jump_strength : float = 6.0
## Toggles on or off constant jump height
@export var constant_jump : bool = false
## How much of the original velocity along the gravity direction should be removed each frame when pressing the jump key.
@export var variable_jump_dampening : float = 2



func _ready() -> void:
	if !component_name or component_name == "":
		component_name = "jump_component"

func _physics_process(delta: float) -> void:
	# Jump related functions
	_handle_jump()
	_dampen_fall(delta) # Has an effect when constant_jump is disabled

func _handle_jump() -> void:
	# Determina se il personaggio è a terra, usando la logica di ground detection attiva.
	var is_currently_on_floor : bool = controller.is_on_floor()
	#print(is_currently_on_floor)
	
	var jump_requested : bool = Input.is_action_pressed("jump")
	var should_jump : bool = false
	
	# Condizione di Salto 1: Tasto premuto mentre si è a terra (Salto Immediato)
	if jump_requested and is_currently_on_floor:
		should_jump = true
	
	if should_jump:
		controller.velocity += controller.up_direction * jump_strength

func _dampen_fall(delta : float) -> void:
	if !constant_jump and Input.is_action_pressed("jump"):
		controller.velocity -= (controller.gravity_direction * controller.gravity * delta)/3 # A third of the formula for gravity is dampened
