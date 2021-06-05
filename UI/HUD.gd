extends CanvasLayer

onready var belly_flop = $BellyFlopButton
onready var tank_main_lox = $FuelGauge/MainLox
onready var tank_main_methane = $FuelGauge/MainMethane
onready var elevation_label = $ElevationLabel

func _on_Can_Belly_Flop( value ) -> void:
	belly_flop.visible = value

func _on_Fuel_Updated( total_fuel, remaining_fuel ) : 
	var fuel_percentage = (total_fuel - remaining_fuel) / total_fuel * 100
	fuel_percentage = 100 - fuel_percentage
	tank_main_lox.value = clamp( fuel_percentage, 0, 100 )
	tank_main_methane.value = clamp( fuel_percentage, 0, 100 )

func _on_Elevation_Updated( elevation ) :
	elevation_label.text = str(elevation)
