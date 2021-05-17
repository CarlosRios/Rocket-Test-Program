extends Node2D

onready var engines = get_children()

# Turn on the engines
func _on_Starship_engines_on( throttle ) -> void:
	for engine in engines :
		engine.fire_engine( throttle )

# Gimbal the engines
func _on_Starship_steer_engines( direction ) -> void:
	for engine in engines : 
		engine.set_engine_rotation( direction )
