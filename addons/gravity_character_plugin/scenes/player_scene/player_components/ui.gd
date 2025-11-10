extends CanvasLayer



@export var tooltip_outline_size : float = 2
@export var tooltip_outline_color_codename : String = "black"
@export var parent : GravityController3D:
	get:
		if !parent:
			parent = get_parent() if get_parent() is GravityController3D else null
		return parent

@onready var dash_bar: TextureProgressBar = $HUD/MarginContainer/VBoxContainer/DashBar
@onready var state_label: Label = $HUD/State
@onready var fps_label: Label = $HUD/FPS
@onready var speed_label: Label = $HUD/Speed
@onready var health_bar: TextureProgressBar = %HealthBar
@onready var energy_bar: TextureProgressBar = %EnergyBar
@onready var hurt_overlay: ColorRect = $HUD/HurtOverlay
@onready var low_health: ColorRect = $HUD/LowHealth

var parent_state_machine : ComponentStateMachine:
	get:
		if !parent_state_machine and parent:
			parent_state_machine = parent.get_statemachine_if_present()
		return parent_state_machine
var component_container : ComponentContainer:
	get:
		if !component_container and parent.component_container:
			component_container = parent.component_container
		return component_container
var dash_cooldown: float = 0.0
var max_energy: float = 0.0

var on_low_health: bool = false:
	set(state):
		on_low_health = state
		if low_health != null:
			low_health.show() if state else low_health.hide()

var passed_time: float = 0.0

func _ready() -> void:
	for component in parent.component_container.get_components():
		if component is HealthComponent:
			component.health_changed.connect(_on_health_changed)
			health_bar.max_value = component.max_health
			component.damaged.connect(_damaged)
		if component is DashComponent:
			component.cooldown_changed.connect(_on_cooldown_changed)
			dash_cooldown = component.dash_cooldown
			#component.dash.connect(func(): print("Dashed"))
			#component.g_slam.connect(func(): print("G-slammed"))
		if component is AbilitiesComponent:
			component.energy_changed.connect(_on_energy_changed)
			max_energy = component.max_energy

func _process(delta: float) -> void:
	fps_label.text = "FPS: %.3f"%Engine.get_frames_per_second()
	_update_speed_label()
	_update_state_label()
	_low_health_animation(delta)

func _update_speed_label() -> void:
	speed_label.text = "Veloc: {speed} m/s\nV  xz: {horizontal_speed} m/s\nV   y: {vertical_speed} m/s".format({"speed":"%.3f"%parent.velocity.length(),"horizontal_speed":"%.3f"%parent.get_horizontal_velocity().length(),"vertical_speed":"%.3f"%parent.get_vertical_velocity_scalar()})

func _update_state_label() -> void:
	if parent_state_machine:
		state_label.text = parent_state_machine.current_state.state_name


func _low_health_animation(delta: float) -> void:
	passed_time += delta
	#print("Is on low health? "+ ("Yes" if on_low_health else "No"))
	if on_low_health:
		(low_health.material as ShaderMaterial).set_shader_parameter("intensity",sin(2*PI*passed_time))
		#print("Passed time: %s, sin(passed_time): %s"%[str(passed_time),str(sin(passed_time))])

func _update_health_bar(value: float) -> void:
	print("Health changed to: %.3f"%value)
	var target = value
	var target_tween : Tween = get_tree().create_tween()
	target_tween.set_ease(Tween.EASE_IN)
	target_tween.tween_property(health_bar,"value", target, 0.05)
	if value <= 0.0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_health_changed(from: float, to: float):
	_update_health_bar(to)
	if to <= 25.0:
		#print("\n\n\n\n\n\n\n\nHEALTH CRITICALLY LOW\n\n\n\n\n\n\n\n")
		on_low_health = true
	else:
		#print("\n\n\n\n\n\n\n\nNAH JK! IT's ALL GOOD G\n\n\n\n\n\n\n\n")
		on_low_health = false

func _on_cooldown_changed(from: float, to: float):
	dash_bar.value = _map_range(to, dash_cooldown, 0.0, 0.0, 100.0)

func _on_energy_changed(from: float, to: float) -> void:
	#print("Energy changed")
	var target = _map_range(to,0.0, max_energy, 0.0, 100.0)
	var target_tween : Tween = get_tree().create_tween()
	target_tween.set_ease(Tween.EASE_IN)
	target_tween.tween_property(energy_bar,"value", target, 0.05)

func _damaged(amount: float) -> void:
	var in_tween: Tween = get_tree().create_tween()
	in_tween.set_ease(Tween.EASE_IN)
	in_tween.set_trans(Tween.TRANS_BOUNCE)
	in_tween.tween_property(hurt_overlay, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.05)
	await in_tween.finished
	await get_tree().create_timer(0.05).timeout
	var out_tween: Tween = get_tree().create_tween()
	out_tween.set_ease(Tween.EASE_OUT)
	out_tween.set_trans(Tween.TRANS_BOUNCE)
	out_tween.tween_property(hurt_overlay, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.05)

## Helper function to map a value from one range to another.
func _map_range(value: float, low1: float, high1: float, low2: float, high2: float) -> float:
	return low2 + (value - low1) * (high2 - low2) / (high1 - low1)
