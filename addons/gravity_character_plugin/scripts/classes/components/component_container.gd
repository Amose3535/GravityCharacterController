@tool
extends Node
class_name ComponentContainer
## A class used as a "folder" or a container for other components in a scene. 
## It automatically assigns the parent GravityController3D to all BaseComponent children.

# Riferimento al nodo GravityController3D padre
var controller: GravityController3D = null

# Flag che indica se il setup è corretto
var is_setup_ok: bool = false

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_check_setup_and_assign()

func _enter_tree() -> void:
	_check_setup_and_assign()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_check_setup_and_assign()

# ==============================================================================
# SETUP CORE LOGIC
# ==============================================================================

## Verify parent and assign controller to all child component. Uses _set_controller_node() to apply the controller variable.
func _check_setup_and_assign() -> void:
	var parent_candidate = get_parent()
	
	# 1. VERIFICA IL NODO PADRE
	if parent_candidate is GravityController3D:
		controller = parent_candidate
		is_setup_ok = true
	else:
		controller = null
		is_setup_ok = false
		
	# 2. SEGNALA LA NECESSITÀ DI AGGIORNARE LE WARNINGS NELL'EDITOR
	notify_property_list_changed()
	
	# 3. ASSEGNA IL CONTROLLER AI COMPONENTI FIGLI
	if is_setup_ok:
		_set_controller_node()

## Assign 'controller' variable to all 'BaseComponent' children. Child nodes with a different class will be ignored.
func _set_controller_node() -> void:
	if !controller:
		return
		
	for child in get_children():
		if child is BaseComponent: 
			(child as BaseComponent).controller = controller

# ==============================================================================
# EDITOR WARNINGS
# ==============================================================================

func _get_configuration_warnings() -> PackedStringArray:
	var warns: PackedStringArray = []
	
	# Non usare 'is_setup_ok' direttamente, ricontrolla per precisione
	if !get_parent() is GravityController3D:
		warns.append("This node must be a direct child of a 'GravityController3D' node.")
	
	return warns
