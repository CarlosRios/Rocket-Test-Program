extends Node2D

# Exported variables
export (int) var strength = 100

# Onreadys
onready var spacecraft = get_parent().get_parent()
onready var exhaust = $ColdGasExhaust

func _activate_thruster(direction) :
	if direction == "up" :
		spacecraft.apply_impulse(self.position, Vector2(0, strength) )
	elif direction == "down" :
		spacecraft.apply_impulse(self.position, Vector2(0, -strength) )

	$Timer.start()
	exhaust.emitting = true

func _on_Timer_timeout() -> void:
	exhaust.emitting = false
