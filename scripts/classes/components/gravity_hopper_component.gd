extends BaseComponent
class_name GravityHopperComponent

@export_range(0.1,100,0.1,"or_greater") var gravity_hop_range : float = 100.0:
	set(new_range):
		if controller:
			if controller.head:
				gravity_hopper_raycast.target_position = -controller.head.transform.basis.z * new_range
			else:
				gravity_hopper_raycast.target_position = -controller.transform.basis.z * new_range
		gravity_hop_range = new_range

@onready var gravity_hopper_raycast : RayCast3D = RayCast3D.new()

func _ready() -> void:
	if !CORRECT_SETUP: return
	if !controller: return
	if !gravity_hopper_raycast:
		gravity_hopper_raycast = RayCast3D.new()
	if controller.head:
		# Add the raycast as a child of the head and set target position
		controller.head.add_child(gravity_hopper_raycast)
		gravity_hopper_raycast.target_position = -controller.head.transform.basis.z * gravity_hop_range
	else:
		controller.add_child(gravity_hopper_raycast)
		gravity_hopper_raycast.target_position = -controller.transform.basis.z * gravity_hop_range
	
	gravity_hopper_raycast.add_exception(controller)

func _unhandled_input(event: InputEvent) -> void:
	# If the setup is incorrect, return
	if !CORRECT_SETUP: return
	if _get_configuration_warnings().size() == 0:
		if event is InputEventKey:
			if event.is_action_pressed("hop"):
				#print("Distance: %f"%gravity_hop_range)
				if gravity_hopper_raycast.get_collider() != null:
					controller.set_new_gravity_direction(-gravity_hopper_raycast.get_collision_normal())
					#print("Normal direction: %s"%get_collision_normal())
			if event.is_action_pressed("de_hop"):
				var default_gravity : Vector3 = ProjectSettings.get_setting("physics/3d/default_gravity_vector")
				controller.set_new_gravity_direction(default_gravity)

func _get_configuration_warnings() -> PackedStringArray:
	var warns : PackedStringArray = PackedStringArray([])
	if !CORRECT_SETUP:
		warns.append("The controller node of this GraivityHopperComponent isn't set up. Make sure to correctly set it up before trying to use it.")
	return warns
