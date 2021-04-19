extends CanvasLayer

onready var belly_flop = $ActionButtons/BellyFlopButton
onready var fuel = $Fuel

func show_belly_flop_button( value ) -> void:
	belly_flop.visible = value

func set_fuel_level( total_fuel, remaining_fuel ) : 
	var fuel_percentage = (total_fuel - remaining_fuel) / total_fuel * 100
	fuel_percentage = 100 - fuel_percentage
	fuel.value = clamp(fuel_percentage, 0, 100)
