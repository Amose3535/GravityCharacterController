# gravity_character_body_3d.gd
extends CharacterBody3D
class_name GravityCharacter3D
## A base class that adds functionality and utilities on CharacterBody3D to have a neat integration with custom gravity vectors. 


signal gravity_changed(from: Vector3, to: Vector3)


## The direction that gravity is applied. This is the very core of this class.
@export var gravity_direction : Vector3 = Vector3.DOWN:
	set(new_dir):
		_on_gravity_changed(gravity_direction, new_dir)
		emit_signal("gravity_changed",gravity_direction,new_dir)
		if new_dir == Vector3.ZERO:
			return
		gravity_direction = new_dir.normalized()
		up_direction = -gravity_direction


@export_group("Gravity")
## Gravity strength (by default 9.807)
@export var gravity : float = 9.807



#region CUSTOM FUNCTIONS
## API used to execute some user-defined logic using this neat function called upon gravity change.[br]IT's empty by default.
func _on_gravity_changed(old_direction : Vector3, new_direction : Vector3) -> void:
	pass


## API used to get the velocity component (with respect to the up_direction / -gravity_direction). It's reccomended to use a normalized vector
func get_velocity_parallel(to : Vector3) -> Vector3:
	return velocity.project(to) if !to.is_equal_approx(Vector3.ZERO) else Vector3.ZERO # dude, it's basically plain english lmao

## API used to get the scalar of the velocity along the up_direction
func get_vertical_velocity() -> float:
	return get_velocity_parallel(up_direction).length()

## API used to get the velocity component horizontal to the ground (and therefore pependicular to up_direction)
func get_horizontal_velocity() -> Vector3:
	return velocity - get_velocity_parallel(up_direction)


## API used from child script/components to project a vector v onto a plane with normal n.[br]This is commonly used to find the movement on walls and surfaces.
static func project_on_plane(v: Vector3, n: Vector3) -> Vector3:
	return v - n * v.dot(n)
#endregion CUSTOM FUNCTIONS
