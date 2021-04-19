extends Node2D

onready var rcs = $Particles2D

func _on_Timer_timeout() -> void:
	# Removes the node from memory on Timer timeout
	queue_free()
