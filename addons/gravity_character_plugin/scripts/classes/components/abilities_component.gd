# abilities_component.gd
extends BaseComponent
class_name AbilitiesComponent
## A component made to handle player abilities (such as special attacks / perks / stat boost, etc)

signal energy_changed(from: float, to: float)
signal energy_maxed_out
signal energy_drained

@export var max_energy: float = 100.0
@export var regen_enabled: bool = true
@export var energy_regen_rate: float = 1.0
@export var abilities: Array[BaseAbility] = []



var energy: float = max_energy:
	set(new_energy_amount):
		energy_changed.emit(max_energy, new_energy_amount)
		#print("Energy changed from: %.3f to: %.3f"%[energy, new_energy_amount])
		energy = clamp(new_energy_amount, 0.0, max_energy)
		if new_energy_amount >= max_energy:
			energy_maxed_out.emit()
		elif new_energy_amount <= 0.0:
			energy_drained.emit()

var can_regen: bool:
	get:
		return (energy < max_energy) && regen_enabled

# This is commonly used to setup the stuff the component needs
func _ready() -> void:
	energy = max_energy
	if abilities != null && abilities.size() > 0 && controller != null:
		for ability in abilities:
			if !ability: continue
			# If an error pops up here, cut and paste the next line, sometimes happens with cyclic references.
			ability.handler_component = self
			ability.controller = controller
			ability._ready_ability()

func _process(delta: float) -> void:
	if abilities != null && abilities.size() > 0:
		for ability in abilities:
			if !ability: continue
			ability._process_ability(delta)

func _physics_process(delta: float) -> void:
	if abilities != null && abilities.size() > 0:
		for ability in abilities:
			if !ability: continue
			ability._physics_process_ability(delta)
	
	if can_regen:
		energy += energy_regen_rate*delta
	_update_triggers()

func _update_triggers():
	if abilities != null && abilities.size() > 0:
		for ability in abilities:
			if !ability: continue
			if ability._can_trigger():
				if !can_consume(ability.ability_cost): continue
				consume_energy(ability.ability_cost)
				ability.triggered()

func can_consume(cost: float) -> bool:
	return (false if (energy - cost < 0.0) else true)

func consume_energy(cost: float) -> void:
	energy -= cost
