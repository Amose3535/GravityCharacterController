extends BaseComponent
class_name MouseHandlerComponent
## NOTE: Could be turned into an autoload. IDK


## Wether to auto capture mouse at start
@export var auto_mouse_capture : bool = true

## The state of the mouse
var mouse_captured : bool = false

func _ready() -> void:
	if !component_name or component_name == "":
		component_name = "mouse_handler_component"
	if auto_mouse_capture:
		toggle_mouse_mode() # capture mouse

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			toggle_mouse_mode()

func toggle_mouse_mode() -> void:
	if mouse_captured:
		mouse_captured = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		mouse_captured = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
