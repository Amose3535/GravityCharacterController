extends BaseComponent
class_name HealthComponent
## A component that adds health, harming, and healing

## Emitted upon health change, before any health boundary check is applied
signal changing_health(requested: float, current: float)
## Emitted upon health change, AFTER some checks have been applied
signal health_changed(from: float, to: float)
## Emitted upon health depletion
signal died()
## Emitted upon health maxing
signal health_maxed_out()
## Emitted when damage() function is called
signal damaged(damage_amount: float)
## Emitted when heal() function is called
signal healed(heal_amount: float)

## The max health that the player is given.
@export var max_health : float = 100.0
## The current health of the player
@export var current_health : float = 100.0:
	set(new_health):
		changing_health.emit(new_health,current_health)
		if new_health <= 0.0:
			new_health = 0.0
			if current_health > 0:
				died.emit()
		if new_health > max_health:
			new_health = max_health
			health_maxed_out.emit()
		print("Health changed from: %.3f to: %.3f"%[current_health,new_health])
		health_changed.emit(current_health, new_health)
		current_health = new_health

func _ready() -> void:
	died.connect(_die)

## API used to take damage
func damage(damage: float) -> void:
	damaged.emit(damage)
	current_health-=damage

## API used to heal the player
func heal(health: float) -> void:
	healed.emit(health)
	current_health+=health

## Internal function run when the character dies: Disables FSM and all components
func _die() -> void:
	controller.process_mode = Node.PROCESS_MODE_DISABLED
	controller.velocity = Vector3.ZERO
	controller.state_machine.enabled = false
	for component in controller.component_container.get_components():
		component.active = false
