extends Node2D

export (int) var max_thrust = 1000
export (bool) var can_gimbal = true
export (float) var max_gimbal = 35.0

# The initial values
var gimbal_rotation = 0.0
var thrust = 0

onready var spacecraft = get_parent().get_parent()
onready var exhaust = $EngineExhaust

func set_engine_rotation( direction ) :
	if can_gimbal :
		if direction != null :
			if direction == "right":
				gimbal_rotation += 0.5
			elif direction == "left":
				gimbal_rotation += -0.5
		else :
			gimbal_rotation = 0

		gimbal_rotation = clamp( gimbal_rotation, -max_gimbal, max_gimbal )
		self.rotation_degrees = gimbal_rotation

# Gimbal the engines
# Emit the particles on a timer
# Apply thrust to the spacecraft
# Engines also provide a small amount of torque to the spacecraft
# Thrust is max_thrust * (throttle / 100)
func fire_engine( throttle ) -> void:
	thrust = max_thrust * (throttle / 100)
	
	if gimbal_rotation > 0 or gimbal_rotation < 0 :
		var torque = gimbal_rotation * thrust
		spacecraft.apply_torque_impulse( torque )

	exhaust.process_material.set("initial_velocity", throttle / 3 )
	$Timer.start()
	exhaust.emitting = true

	# We want to apply the impulse from where the engine is, and according to its GLOBAL rotation
	var gimballed_spacecraft = spacecraft.rotation_degrees + gimbal_rotation

	# Apply the thrust to the spacecraft
	var thrust_vector = Vector2(0, -thrust)
	spacecraft.apply_impulse( self.position, thrust_vector.rotated( deg2rad( gimballed_spacecraft ) ) )

func _on_Timer_timeout() -> void:
	exhaust.emitting = false
