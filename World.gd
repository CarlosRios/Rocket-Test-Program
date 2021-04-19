extends Node2D

export var smoke_effect: PackedScene

func generate_smoke_effect( hit_position: Vector2 )->void:
	var temp = smoke_effect.instance()
	add_child(temp)
	temp.position = hit_position


func _on_Starship_launching( hit_position: Vector2) -> void:
	generate_smoke_effect(hit_position)

# Connect signals here between instanced scenes
func _ready():
	$Starship.connect("fuel_updated", $HUD, "set_fuel_level")
	$Starship.connect("can_belly_flop", $HUD, "show_belly_flop_button")
	
	# HUD items to connect to Starship
	$HUD/Throttle.connect("value_changed", $Starship, "_on_Throttle_value_changed")
