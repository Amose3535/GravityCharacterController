# wall_slide_component
extends BaseComponent
class_name WallSlideComponent
## A component that dampens fall when the character is on a wall

# Velocità massima di scivolamento sul muro
@export var wall_slide_speed: float = 5.0 # Un valore 3D tipico è intorno a 5.0

## How fast does your vertical speed change when 
@export var wall_friction_force: float = 10.0


func _physics_process(delta: float) -> void:
	_apply_wall_slide(delta)

func _apply_wall_slide(delta: float):
	
	# Condition: on wall and not on floor
	if controller.is_on_wall() and not controller.is_on_floor():
		#print("WALLSLIDING")
		var velocity := controller.velocity
		var lateral_velocity := velocity
	
		# --- 1. CLAMPING (Limitazione) della Velocità di Caduta ---
		
		# Calcola la componente SCALARE della velocità lungo l'asse verticale (gravity_direction)
		# Se > 0, il personaggio sta cadendo/muovendosi verso la gravità.
		var current_downward_speed = -controller.get_vertical_velocity_scalar()
		# VEC-TORE: Calcola la VEC-TORE attuale della caduta
		var downward_velocity_vector = controller.gravity_direction * current_downward_speed
		# VEC-TORE: Calcola la VEC-TORE clampata (la nuova velocità di scivolamento)
		var clamped_downward_velocity_vector = controller.gravity_direction * wall_slide_speed
		
		# Se il personaggio sta cadendo E la sua velocità supera il limite di slide...
		if current_downward_speed > wall_slide_speed:
			# Aggiorna la velocity: Sottrai la vecchia componente di caduta e aggiungi la nuova (limitata)
			velocity += clamped_downward_velocity_vector - downward_velocity_vector
	
		# --- 2. FORZA ADESIVA LATERALE (per non staccarsi) ---
		
		# Rimuovi la componente della velocità che è laterale (parallela al muro)
		# Questo impedisce al movimento laterale di "staccare" il personaggio dal muro troppo facilmente.
		
		# Calcola la velocità laterale (proiezione della velocity sul piano perpendicolare a gravity_direction)
		lateral_velocity = velocity - (downward_velocity_vector+clamped_downward_velocity_vector)
		
		# Linear interpolate 
		velocity = lerp(velocity, velocity - lateral_velocity, wall_friction_force * delta)
		
		# Imposta la nuova velocity
		controller.velocity = velocity
