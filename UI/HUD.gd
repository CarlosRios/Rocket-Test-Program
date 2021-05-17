extends CanvasLayer

onready var belly_flop = $ActionButtons/BellyFlopButton
onready var fuel = $Fuel

func _on_Can_Belly_Flop( value ) -> void:
	belly_flop.visible = value

func _on_Fuel_Updated( total_fuel, remaining_fuel ) : 
	var fuel_percentage = (total_fuel - remaining_fuel) / total_fuel * 100
	fuel_percentage = 100 - fuel_percentage
	fuel.value = clamp(fuel_percentage, 0, 100)