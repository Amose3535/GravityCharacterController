# wall_stick_component.gd
extends BaseComponent
class_name WallStickComponent
## A component used to stick to the wall you're on.

#region EXPORTS
## Forza che spinge il personaggio nel muro (per l'adesione).
@export var stick_force: float = 30.0
## Raggio di rilevamento (margine dal raggio del player).
@export var wall_check_radius_margin: float = 0.1
## Max results che lo ShapeCast può restituire.
@export var max_wall_contacts: int = 8
#endregion EXPORTS

@onready var wall_shapecast: ShapeCast3D = ShapeCast3D.new()


func _ready() -> void:
	if !component_name or component_name == "":
		component_name = "wall_movement_component"
	_setup_wall_shapecast()


func _physics_process(delta: float) -> void:
	_stick_to_wall(delta)


## Applies small force to stick player to wall
func _stick_to_wall(delta: float) -> void:
	if !wall_shapecast.is_inside_tree(): return
	wall_shapecast.force_shapecast_update()
	
	if !wall_shapecast.is_colliding(): return
	
	var collision_count: int = wall_shapecast.get_collision_count()
	if collision_count == 0: return
	
	var resulting_normal: Vector3 = Vector3.ZERO
	for i in range(collision_count):
		resulting_normal += wall_shapecast.get_collision_normal(i)
	
	if abs(resulting_normal.dot(controller.up_direction)) > cos(deg_to_rad(controller.floor_max_angle)): return
	
	var velocity : Vector3 = Vector3.ZERO
	velocity += -resulting_normal * stick_force
	
	controller.velocity += velocity

## Configura e aggiunge lo ShapeCast al Controller.
func _setup_wall_shapecast() -> void:
	if !wall_shapecast: return
	
	# Assicura che il nodo sia aggiunto in sicurezza (risolve il crash del ready)
	controller.call_deferred("add_child", wall_shapecast)
	wall_shapecast.add_exception(controller)
	
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
