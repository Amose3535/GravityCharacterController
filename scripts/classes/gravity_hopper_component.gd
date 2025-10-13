@tool
extends RayCast3D
class_name GravityHopperComponent
## A component that extends raycasts to set thee GravityCharacter's Gravity direction to the normal of a surface at the click of a button.

@export var gravity_character : GravityCharacter3D = null
@export_range(0.1,100,0.1) var gravity_hop_range : float = 100.0:
	set(new_range):
		if gravity_character:
			if gravity_character.head:
				target_position = -gravity_character.head.transform.basis.z * new_range


func _get_configuration_warnings() -> PackedStringArray:
	var warns : PackedStringArray = PackedStringArray([])
	if (gravity_character == null) or !(gravity_character is GravityCharacter3D):
		warns.append("The GravityCharacter3D node of this GraivityHopperComponent isn't set up: this node won't work until it's correctly set up.")
	return warns

func _ready() -> void:
	if gravity_character:
		add_exception(gravity_character)
		if gravity_character.head:
			target_position = -gravity_character.head.transform.basis.z * gravity_hop_range
		
		

func _unhandled_input(event: InputEvent) -> void:
	if _get_configuration_warnings().size() == 0:
		if event is InputEventKey:
			if event.is_action_pressed("hop"):
				print("Distance: %f"%gravity_hop_range)
				if get_collider() != null:
					gravity_character.set_new_gravity_direction(-get_collision_normal())
					print("Normal direction: %s"%get_collision_normal())
