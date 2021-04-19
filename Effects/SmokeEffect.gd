extends Node2D

onready var particle = $Particles2D

func _ready() :
	particle.emitting = true

func _on_Timer_timeout() -> void:
	# Removes the node from memory on Timer timeout
	queue_free()
