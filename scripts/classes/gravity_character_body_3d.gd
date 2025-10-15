# gravity_character_body_3d.gd
extends CharacterBody3D
class_name GravityCharacter3D
## A base class that adds functionality and utilities on CharacterBody3D to have a neat integration with custom gravity vectors. 


signal gravity_changed(from: Vector3, to: Vector3)


## The direction that gravity is applied. This is the very core of this class.
@export var gravity_direction : Vector3 = Vector3.DOWN:
	set(new_dir):
		_on_gravity_change(gravity_direction, new_dir)
		emit_signal("gravity_changed",gravity_direction,new_dir)
		if new_dir == Vector3.ZERO:
			return
		gravity_direction = new_dir.normalized()
		up_direction = -gravity_direction
		if reset_attraction_on_gravity_change:
			last_ground_contact = 0


@export_group("Gravity")
## Gravity strength (by default 9.807)
@export var gravity : float = 9.807
## The speed at which the body will rotate (with its feet DOWN) towards the desired direction
@export var align_speed : float = 5.0
## Determines wether to reset the timer that measures the last_ground_contact upon gravity change
@export var reset_attraction_on_gravity_change : bool = true
## Toggles cooldown for gravity direction changes
@export var gravity_change_cooldown : bool = false
## How much time (in seconds) passes before the gravity can change again
@export var gravity_cooldown : float = 1.0



## last time since touching ground (commonly used for gravity)
var last_ground_contact : float = 0.0
## Time passed since the last gravity change (used for cooldown).
var last_gravity_change : float = 0.0


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PHYSICS_PROCESS:
			_update_last_gravity_change(get_physics_process_delta_time())


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

## API used to execute some user-defined logic using this neat function called upon gravity change
func _on_gravity_change(old_direction : Vector3, new_direction : Vector3) -> void:
	pass

func _update_last_gravity_change(delta : float) -> void:
	last_gravity_change += delta

## API used to project a vector v onto a plane with normal n. This is commonly used to find the movement on walls and surfaces.
static func project_on_plane(v: Vector3, n: Vector3) -> Vector3:
	return v - n * v.dot(n)
#endregion CUSTOM FUNCTIONS
