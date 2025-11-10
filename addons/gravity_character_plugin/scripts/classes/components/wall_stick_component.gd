# wall_stick_component.gd
extends BaseComponent
class_name WallStickComponent
## A component used to stick to the wall you're on.

#region EXPORTS
## Forza che spinge il personaggio nel muro (per l'adesione).
@export var stick_force: float = 30.0
## What layers will the ShapeCast3D check for collisions
@export_flags_3d_physics var mask: int = 1
## Extra margin to add on the player's collision radius to have the final margin used as check
@export var wall_check_radius_margin: float = 0.1
## Max results che lo ShapeCast può restituire.
@export var max_wall_contacts: int = 8
## This determines the smallest angle between the player's down direction (-gravity_direction.normalized()) and the resulting normal. Hence if the opposite of the resulting normal (because the force is applied using -resulting_normal) goes too near to this angle, and hang_to_wall_end is set to false, then it will fall, otherwise it will stop
@export var max_wall_normal_angle: float = 90.0
## When reaching the end of a wall suspended in air, it decides wether to try to hang to the ledge or not
@export var hang_to_wall_end: bool = true
## When reaching the end of a wall, if you can hang to it, this determines wether you stop at the end or keep wobbling up and down
@export var stop_at_wall_end: bool = true
#endregion EXPORTS

@onready var wall_shapecast: ShapeCast3D = null

var reached_wall_end: bool = false:
	set(new_state):
		reached_wall_end = new_state
		controller.gravity_enabled = !reached_wall_end


func _ready() -> void:
	if !component_name or component_name == "":
		component_name = "wall_movement_component"
	_setup_wall_shapecast()



func _physics_process(delta: float) -> void:
	_stick_to_wall(delta)
	#print("Reached end of wall? " + ("Yes" if reached_wall_end else "No"))

# TODO: Fix this shit cause for whatever reason i'm so stupid that it won't work
## Applies small force to stick player to wall
func _stick_to_wall(delta: float) -> void:
	if !wall_shapecast: return
	if !wall_shapecast.is_inside_tree(): return
	wall_shapecast.force_shapecast_update()
	
	if !wall_shapecast.is_colliding(): 
		reached_wall_end = false
		return
	
	
	var collision_count: int = wall_shapecast.get_collision_count()
	if collision_count == 0: return
	#reached_wall_end = false
	
	var resulting_normal: Vector3 = Vector3.ZERO
	var gravity_dir: Vector3 = controller.gravity_direction.normalized()
	var dot_threshold: float = cos(deg_to_rad(max_wall_normal_angle)) # La tua soglia originale
	
	#print("--------- PLS WORK ---------")
	#print("Normals found: %d"%collision_count)
	for i in range(collision_count):
		var normal : Vector3 = wall_shapecast.get_collision_normal(i)
		resulting_normal += normal
		var dot_product = normal.dot(gravity_dir)
		if dot_product > dot_threshold:
			reached_wall_end = true
			#print("Reached wall end (Bottom/Floor detected)!")
			break
		else:
			reached_wall_end = false
		#print("Normal {i})\nNormal vector: {vec},\nGravity dir: {gdir},\nDot prod: {dpd},\nDot threshold: {thrsh}\n\n")
	#print("----------------------------")
	
	var velocity : Vector3 = Vector3.ZERO
	velocity += -resulting_normal * stick_force
	
	# Apply sticking force ONLY when is on wall EXCLUSIVELY (or you might get stuck to walls at ground level)
	if !controller.is_on_wall_only(): return
	if !reached_wall_end:
		controller.velocity += velocity
	else:
		if hang_to_wall_end:
			if stop_at_wall_end && !Input.is_action_pressed("jump"):
				controller.velocity -= controller.get_vertical_velocity()
		else:
			controller.velocity += velocity

## Configura e aggiunge lo ShapeCast al Controller.
func _setup_wall_shapecast() -> void:
	if !wall_shapecast: wall_shapecast = ShapeCast3D.new()
	wall_shapecast.name = "StickCast"
	controller.add_child.call_deferred(wall_shapecast, true)
	wall_shapecast.add_exception(controller)
	wall_shapecast.collision_mask = mask
	
	var sphere_shape = SphereShape3D.new()
	var base_radius = _get_player_radius()
	sphere_shape.radius = base_radius + wall_check_radius_margin
	
	wall_shapecast.shape = sphere_shape
	wall_shapecast.target_position = Vector3.ZERO
	wall_shapecast.enabled = false # Parte disattivato
	wall_shapecast.max_results = max_wall_contacts
	
	# Abilita il ShapeCast dopo che è stato aggiunto
	wall_shapecast.call_deferred("set_deferred", "enabled", true)
	
## Compute the radius based on the shape of the controller
func _get_player_radius() -> float:
	if controller.collision_shape and controller.collision_shape.shape:
		var shape = controller.collision_shape.shape
		if shape.has_method("get_radius"):
			return shape.get_radius() 
		if shape is BoxShape3D:
			return max((shape as BoxShape3D).size.x, (shape as BoxShape3D).size.z) / 2.0
	return 0.5 # Fallback
