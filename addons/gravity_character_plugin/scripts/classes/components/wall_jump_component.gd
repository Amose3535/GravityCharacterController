# wall_jump_component.gd
extends BaseComponent
class_name WallJumpComponent
## A component that applies an horizontal and vertical impulse upon input when the player is on a wall.

#region EXPORTS
@export_group("Wall Jump")
## Horizontal force applied from the wall.
@export var push_strength_horizontal: float = 8.0 
## Vertical force applied during the pushing
@export var push_strength_vertical: float = 6.0 
## The layers the ShapeCast3D will check for collisions
@export_flags_3d_physics var mask: int = 1
## Radius of wall detection for push strength
@export var wall_check_radius_margin: float = 0.1 
## How many wall contacts there can be at one time
@export var max_wall_contacts : int = 8
## Time (in seconds) between possible wall jumps.
@export var wall_jump_cooldown: float = 0.5 
#endregion EXPORTS

#region VARIABLES
## ShapeCast used for wall(s) detection
@onready var wall_check_shape_cast: ShapeCast3D = null
## Cooldown timer (able to jump when timer<= 0)
var cooldown_timer: float = 0.0
#endregion VARIABLES

func _ready() -> void:
	_setup_shape_cast()
	if !component_name or component_name == "":
		component_name = "wall_jump_component"

func _physics_process(delta: float) -> void:
	_update_cooldown_timer(delta)
	_handle_wall_jump()

## Configure ShapeCast and add it to the controller.
func _setup_shape_cast() -> void:
	# Create new shapecast, add it to the controller and configure it
	if !wall_check_shape_cast: wall_check_shape_cast = ShapeCast3D.new() # Create new shapecast when necessary
	wall_check_shape_cast.name = "JumpCast"
	controller.add_child.call_deferred(wall_check_shape_cast, true) # Add new shapecast to controller (but do it deferredly to prevent problems)
	wall_check_shape_cast.position = controller.collision_shape.position # Set its position relative to the controller to the same position as the collision shape
	wall_check_shape_cast.add_exception(controller) # Add as shapecast exception the controller
	wall_check_shape_cast.collision_mask = mask
	
	var sphere_shape = SphereShape3D.new()
	var base_radius = _get_player_radius()
	sphere_shape.radius = base_radius + wall_check_radius_margin
	
	wall_check_shape_cast.shape = sphere_shape
	wall_check_shape_cast.target_position = Vector3.ZERO
	wall_check_shape_cast.enabled = true
	wall_check_shape_cast.max_results = max_wall_contacts

## Compute the radius based on the shape of the controller
func _get_player_radius() -> float:
	if controller.collision_shape and controller.collision_shape.shape:
		var shape = controller.collision_shape.shape
		if shape.has_method("get_radius"):
			return shape.get_radius() # get_radius() is in CylinderShape3D, CapsueShape3D and SphereShape3D
		if shape is BoxShape3D:
			# Half of the biggest side
			return max((shape as BoxShape3D).size.x, (shape as BoxShape3D).size.z) / 2.0
			
	return 0.5 # Fallback

## Control conditions and apply walljump
func _handle_wall_jump() -> void:
	if !is_inside_tree(): return
	# Return if on floor, if the timer hasn't expired yet or if the player didn't press the jump input
	if controller.is_on_floor() || cooldown_timer > 0.0 || !Input.is_action_just_pressed("jump"): return
	
	# Update right before use
	wall_check_shape_cast.force_shapecast_update() 
	
	# Condizioni di attivazione: Sei in aria E vicino a un muro
	if !wall_check_shape_cast.is_colliding(): return
	
	# Get collision count, and if 0, return
	var collision_count : int = wall_check_shape_cast.get_collision_count()
	if collision_count == 0: return
	
	# Use a contribution o all normals
	var resulting_normal : Vector3 = Vector3.ZERO
	for i in range(collision_count):
		# Add to the resulting vector the contribution of all possible contact points (from i=0 to i=max_wall_contacts)
		resulting_normal += wall_check_shape_cast.get_collision_normal(i)
	
	# Make sure that the resulting normal isn't too steep (check with controller.floor_max_angle)
	if abs(resulting_normal.dot(controller.up_direction)) > cos(deg_to_rad(controller.floor_max_angle)): return
	
	# Compute horizontal component (along contribution normal)
	var horizontal_push: Vector3 = project_on_plane(resulting_normal, controller.up_direction).normalized() * push_strength_horizontal
	
	# Compute vertical component (along up_direction)
	var vertical_push: Vector3 = controller.up_direction * push_strength_vertical
	
	# Apply new velocity
	controller.velocity += horizontal_push + vertical_push
	
	# restart cooldown
	cooldown_timer = wall_jump_cooldown

## Updates the timer when it's > 0
func _update_cooldown_timer(delta : float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta


static func project_on_plane(v: Vector3, n: Vector3) -> Vector3:
	return v - n * v.dot(n)
