extends Node2D

onready var thrusters = get_children()

func _on_Starship_engines_on( direction ) -> void:
	
	# Turn on the engines
	for thruster in thrusters :
		thruster._activate_thruster( direction )

