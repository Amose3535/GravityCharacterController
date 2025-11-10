# charge_ability.gd
@abstract
extends BaseAbility
class_name ChargeAbility
## Base class for all abilities that require a chargeup

signal charged
signal charge_changed(from: float, to: float)
signal cooldown_changed(from: float, to: float)


## How much charge is required for the ability to trigger
@export var max_charge: float = 10.0
## How fast does the ability charge while the "ability" action is pressed
@export var charge_rate: float = 2.0
## How fast does the ability DIScharge while the "ability" action is released (Set to 0 to never discharge)
@export var discharge_rate: float = 0.5
## Wether the ability should use a cooldown or not. set to false to charge instantaneously 
@export var apply_cooldown: bool = true
## If apply_cooldown is enabled, this determines how much time it's needed for the ability to be able to be recharged again
@export var wait_time: float = 10.0


var ability_charge: float = 0.0:
	set(new_charge_amount):
		if new_charge_amount > ability_charge: 
			#print("Charging up. Now at {val}".format({"val":new_charge_amount}))
			on_charging()
		charge_changed.emit(ability_charge, new_charge_amount)
		ability_charge = clamp(new_charge_amount, 0.0, max_charge)
var cooldown_timer: float = 0.0:
	set(new_time):
		cooldown_changed.emit(cooldown_timer, new_time)
		cooldown_timer = clamp(new_time, 0.0, wait_time)


func _process_ability(delta: float) -> void:
	if apply_cooldown && cooldown_timer > 0:
		cooldown_timer -= delta
	
	var rate: float = 0.0
	if Input.is_action_pressed("ability"):
		#print("Charging ability")
		rate = charge_rate
	else:
		rate = -discharge_rate
	if apply_cooldown:
		if cooldown_timer <= 0:
			ability_charge += delta * rate
	else:
		ability_charge += delta * rate 

func _can_trigger() -> bool:
	return ability_charge >= max_charge

func triggered() -> void:
	#print("Triggered") ## OK
	charged.emit()
	on_charged()
	ability_charge = 0.0
	if apply_cooldown: cooldown_timer = wait_time

@abstract func on_charged() -> void
@abstract func on_charging() -> void
