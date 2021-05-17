extends Node2D

const MAX_ROTATION = 30
const MIN_ROTATION = -30

onready var engine = $Particles2D
var temp_throttle = 0

func _on_Timer_timeout() -> void:
	# Removes the node from memory on Timer timeout
	queue_free()

func _on_Starship_engines_on( emitting, throttle, direction ) -> void:
		
	temp_throttle = throttle 
	
	if direction != null :
		if direction == "right":
			self.rotation_degrees += 1
		elif direction == "left":
			self.rotation_degrees += -1
	else :
		self.rotation_degrees = 0
	
	if self.rotation_degrees >= MAX_ROTATION :
		self.rotation_degrees = MAX_ROTATION
	elif self.rotation_degrees <= MIN_ROTATION :
		self.rotation_degrees = MIN_ROTATION

	self.engine.process_material.set("initial_velocity", temp_throttle )
	self.engine.emitting = emitting
