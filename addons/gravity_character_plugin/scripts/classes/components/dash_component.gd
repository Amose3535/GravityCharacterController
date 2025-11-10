# dash_component.gd
extends BaseComponent
class_name DashComponent
## A component used to implement dashing

signal cooldown_changed(from_time: float, to_time: float)
signal dash
signal g_slam

@export var dash_strength: float = 20.0
@export var dash_cooldown: float = 1.0
@export var cancel_vertical_vel: bool = false
@export var can_dash_on_floor: bool = true
@export var can_dash_on_wall: bool = true
@export var can_ground_slam: bool = true
@export var max_ground_slam_angle: float = 10.0
@export var ground_slam_bonus_strength: float = 10.0

var dash_timer: float = 0.0:
	set(timer):
		if timer < 0.0:
			timer = 0.0
		if timer != dash_timer:
			cooldown_changed.emit(dash_timer,timer)
			dash_timer = timer

var can_dash : bool:
	get:
		if !controller: return false
		can_dash = ((!controller.is_on_floor() if !can_dash_on_floor else true) && (!controller.is_on_wall() if !can_dash_on_wall else true) && !dashed && is_equal_approx(dash_timer,0.0))
		return can_dash

var dash_direction : Vector3:
	get:
		if !controller && !controller.head: return Vector3.ZERO
		if !controller.is_on_floor():
			dash_direction = -controller.head.global_transform.basis.z if controller.head else -controller.global_transform.basis.z
		else:
			dash_direction = -controller.global_transform.basis.z
		return dash_direction

var dashed : bool = false:
	set(state):
		if state:
			dash.emit()
			if slamming && !controller.is_on_floor():
				g_slam.emit()
		dashed = state

var slamming: bool:
	get:
		if !can_ground_slam || controller.is_on_floor():
			return false
		
		# La direzione di mira (forward) del player
		var look_direction: Vector3 = -controller.head.global_transform.basis.z
		
		# La direzione verso il basso (la gravità)
		var gravity_direction: Vector3 = controller.gravity_direction
		
		# 1. Calcola il dot product (coseno dell'angolo)
		# Nota: look_direction e gravity_direction dovrebbero essere normalizzati, ma lo sono già.
		var dot_product = look_direction.dot(gravity_direction)
		
		# 2. Conversione dell'angolo limite in un valore dot product (coseno)
		# floor_max_angle è in gradi, dobbiamo convertirlo in radianti e calcolarne il coseno.
		var angle_limit_cos = cos(deg_to_rad(max_ground_slam_angle))
		
		# Il trigger avviene se la direzione dello sguardo è MOLTO allineata con la gravità.
		# Cioè, se il dot product è MAGGIORE del coseno dell'angolo limite.
		# Esempio: se angle è 10 gradi, cos(10) è ~0.98.
		# Quindi, dot_product (tra 0 e 1) deve essere > 0.98.
		if dot_product > angle_limit_cos:
			return true
		
		return false

func _ready() -> void:
	if !component_name or component_name == "":
		component_name = "dash_component"


func _physics_process(delta: float) -> void:
	_handle_dash(delta)

func _handle_dash(delta: float) -> void:
	if !controller: return
	#print("On floor: {floor} | On wall: {wall} | Dashed: {dashed} | Timer: {timer}".format({"floor":controller.is_on_floor(), "wall":controller.is_on_wall(), "dashed":dashed, "timer":dash_timer}))
	
	if can_dash && Input.is_action_pressed("dash"):
		dashed = true
		dash_timer = dash_cooldown
		if cancel_vertical_vel: controller.velocity -= controller.get_vertical_velocity()
		if slamming: controller.velocity -= controller.get_horizontal_velocity()
		controller.velocity += dash_direction * (dash_strength + (ground_slam_bonus_strength if slamming else 0))
	
	if dash_timer > 0.0:
		dash_timer -= delta
	
	if dashed && ((controller.is_on_floor() or controller.is_on_wall()) or dash_timer == 0.0):
		dashed = false
