# base_ability.gd
@abstract
extends Resource
class_name BaseAbility
## The base class for all abilities

## Emitted when an ability is triggered / activated / applied. Basically it's emitted after the script executed the ability a
signal ability_triggered(energy_cost: float)


## Each ability has a cost, in order to use an ability you need to consume some amount. That amount would be its cost.[br]To make an ability inexpensive you can set it's cost to 0, you can set it in the negatives if you want.
@export var ability_cost: float = 0.0


## The component containing this ability. It's automatically set up so no need to worry for setting this up.
var handler_component: AbilitiesComponent = null
## The controller to which this ability is attached to. Prevents having to do handler_component.controller[...]
var controller: GravityController3D = null


## Function used by the AbilitiesComponent to check if it can be triggered, if so then the AbilitiesComponent calls the triggered() function
func _can_trigger() -> bool:
	return false

func triggered() -> void:
	pass

## Similar to ready but for abilities since resources don't have _ready()
func _ready_ability() -> void:
	pass

## Similar to process but for abilities since resources don't have _process
func _process_ability(delta: float) -> void:
	pass

## Similar to physics process but for abilities since resources don't have _physics_process
func _physics_process_ability(delta: float) -> void:
	pass
