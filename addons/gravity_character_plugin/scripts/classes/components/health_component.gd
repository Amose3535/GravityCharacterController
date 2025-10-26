extends BaseComponent
class_name HealthComponent
## A component that adds health, harming, and healing

## Emitted upon health change, before any health boundary check is applied
signal changing_health(requested: float, current: float)
## Emitted upon health change, AFTER some checks have been applied
signal health_changed(new: float, old: float)
## Emitted upon health depletion
signal health_depleted()
## Emitted upon health maxing
signal health_maxed()
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
		if new_health < 0.0:
			new_health = 0.0
			health_depleted.emit()
		if new_health > max_health:
			new_health = max_health
			health_maxed.emit()
		health_changed.emit(new_health,current_health)
		current_health = new_health

## API used to take damage
func damage(damage: float) -> void:
	damaged.emit(damage)
	current_health-=damage

## API used to heal the player
func heal(health: float) -> void:
	healed.emit(health)
	current_health+=health
