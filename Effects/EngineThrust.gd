extends Node2D

const MAX_ROTATION = 30
const MIN_ROTATION = -30

onready var engine = $Particles2D
var temp_thrust = 0

func _on_Timer_timeout() -> void:
	# Removes the node from memory on Timer timeout
	queue_free()

func _on_Starship_engines_on( emitting, thrust, direction ) -> void:

	if thrust >= -1.0 :
		temp_thrust = -20
	elif thrust >= -2.0:
		temp_thrust = 10
	elif thrust >= -4.0:
		temp_thrust = 40
	elif thrust >= -7.0:
		temp_thrust = 70
		
	
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

	self.engine.process_material.set("initial_velocity", temp_thrust )
	self.engine.emitting = emitting

func flip_manuever_start() :
	_on_Starship_engines_on(false, temp_thrust, "left")
	
func flip_manuever_end() :
	_on_Starship_engines_on(false, temp_thrust, "right")
