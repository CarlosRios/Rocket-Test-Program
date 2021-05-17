extends Node2D

onready var particle_left = $SmokeLeft
onready var particle_right = $SmokeRight

func _ready() :
	particle_left.emitting = true
	particle_right.emitting = true

func _on_Timer_timeout() -> void:
	# Removes the node from memory on Timer timeout
	queue_free()
