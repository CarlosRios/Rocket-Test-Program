extends Node2D

export (int) var max_thrust = 200
export (bool) var can_gimbal = true
export (float) var max_gimbal = 35.0
export (float) var gimbal_torque = 7

# Starting values
var engine_on = false
var gimbal_rotation = 0.0
var thrust = 0
var isp = 330

onready var spacecraft = get_parent().get_parent()
onready var exhaust = $EngineExhaust

# Gimbals the individual engine
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
func apply_thrust( throttle ) -> void:
	thrust = max_thrust * (throttle / 100)
	
	if gimbal_rotation > 0 or gimbal_rotation < 0 :
		var torque = gimbal_rotation * (thrust * 2)
		spacecraft.apply_torque_impulse( torque * gimbal_torque )

	var variable_velocity = 30 * (throttle / 100)

	exhaust.process_material.set("initial_velocity", clamp(variable_velocity, 0.0, 10.0) )
	$Timer.start()
	exhaust.emitting = true

	# We want to apply the impulse from where the engine is, and according to its GLOBAL rotation
	var gimballed_spacecraft = spacecraft.rotation_degrees + gimbal_rotation

	# Apply the thrust to the spacecraft
	var thrust_vector = Vector2(0, -thrust)
	spacecraft.apply_impulse( self.position, thrust_vector.rotated( deg2rad( gimballed_spacecraft ) ) )

# Checks if the engine is on
func is_on() -> bool :
	if engine_on == true :
		return true
	else :
		return false

# Checks if the engine is applying thrust
func is_applying_thrust() -> bool :
	if is_on() and thrust > 0 :
		return true
	else :
		return false

# Things that happen when the engine is lit
func turn_on() :
	engine_on = true

# Should happen as the engine shuts down
func shut_down() :
	engine_on = false
	exhaust.emitting = false
	thrust = 0

func _on_Timer_timeout() -> void:
	exhaust.emitting = false
