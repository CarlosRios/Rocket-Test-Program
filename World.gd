extends Node2D

export var smoke_effect: PackedScene

func generate_smoke_effect( hit_position: Vector2 )->void:
	var temp = smoke_effect.instance()
	add_child(temp)
	temp.position = hit_position

# Connect signals here between instanced scenes
func _ready():
	# Starship > Hud
	$Starship.connect("fuel_updated", $HUD, "_on_Fuel_Updated")
	$Starship.connect("can_belly_flop", $HUD, "_on_Can_Belly_Flop")
	$Starship.connect("elevation_updated", $HUD, '_on_Elevation_Updated')

	# Starship > World
	$Starship.connect("launching", self, "generate_smoke_effect")

	# HUD > Starship
	$HUD/Throttle.connect("value_changed", $Starship, "_on_Throttle_value_changed")
	

