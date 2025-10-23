@tool
extends StaticBody3D

@export var border_distance : float = 50:
	set(new_border_distance):
		if new_border_distance <= 0:
			new_border_distance = 0.1
		border_distance = -new_border_distance
		var children = get_children()
		if children.size() == 0: return
		for child in children:
			if (child is CollisionShape3D) and ((child as CollisionShape3D).shape is WorldBoundaryShape3D):
				(child.shape as WorldBoundaryShape3D).plane.d = border_distance
