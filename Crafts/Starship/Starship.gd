extends RigidBody2D

# Constants
const ExplosionEffect = preload("res://Effects/Explosion.tscn")

# Signals
signal fuel_updated
signal engines_on
signal steer_engines
signal can_belly_flop
signal launching

# Exports
export (float) var max_fuel = 1200
export (float) var max_landing_velocity = 50.00
export (int) var atmosphere_height = 10000

# Variables
var elevation = 0
var thrust = Vector2()
var drag = Vector2()
var lift = Vector2()
var previous_velocity = Vector2.ZERO
var throttle = 0.0
var rotation_dir = 0
var num_of_points = 10
var dry_mass = 12.0

# Conditional Variables
var is_in_the_air = false
var is_falling = false
var is_flopping = false
var is_flipping = false
var is_landed = true
var is_crashed = false
var engines_on = false

# Onreadys
#onready var to_ground = $DistanceFromGround
onready var animationPlayer = $AnimationPlayer
onready var thrust_direction_ray = $ThrustDirectionRay
onready var camera = $Camera2D
onready var remaining_fuel = max_fuel
onready var initial_elevation = global_position.y

# ------------------------------------------------------------------
# Main functions _ready() _physics_process _process
# ------------------------------------------------------------------
func _ready() :
	set_vehicle_mass()
	pass

func _physics_process(_delta: float) :
	_handle_input()
	calculate_trajectory()
	camera.update_camera_zoom(get_elevation())

func _integrate_forces(state: Physics2DDirectBodyState) :
	# Drag
	apply_central_impulse( _calc_drag_forces() )
	return state

# ------------------------------------------------------------------
# Handles the flight input
# ------------------------------------------------------------------
func _handle_input() :
	if Input.is_action_pressed("fire_engines") and remaining_fuel > 0 and throttle > 0.0:
		camera.get_child(1).start()
		update_fuel_level()
		engines_on = true
		emit_signal("engines_on", throttle)
	else :
		engines_on = false
	
	if Input.is_action_pressed("ui_right") :
		apply_rcs_torque("right")
		emit_signal("steer_engines", "right")
	if Input.is_action_pressed("ui_left") :
		apply_rcs_torque("left")
		emit_signal("steer_engines", "left")

	if Input.is_action_just_released("ui_right") or Input.is_action_just_released( "ui_left" ) :
		emit_signal("steer_engines", null)
	
	if Input.is_action_pressed("belly_flop") && can_belly_flop() :
		is_flopping = true

# ------------------------------------------------------------------
# Force / Impulse related functions
# ------------------------------------------------------------------
func apply_rcs_torque( direction, strength = 12000 ) :
	if direction == "left" :
		apply_torque_impulse(-strength)
	else :
		apply_torque_impulse(strength)

# Starship's dry mass is 120 tonnes
# SN Tests weigh about 5000 tonnes
# Raptors max thrust is around 225 tonnes, min is 90 tonnes
func set_vehicle_mass() : 
	var dry_mass = 120
	mass = dry_mass + remaining_fuel
	#print( mass )

func update_fuel_level() :
	var fuel_burn_formula = throttle / 100
	remaining_fuel -= fuel_burn_formula
	set_vehicle_mass()
	emit_signal("fuel_updated", max_fuel, remaining_fuel)

# Calculates how dense the atmosphere is.
# Returns a percentage
func _get_atmosphere_density() :
	# higher is closer to sea level
	# lower is closer to space.
	var density = (atmosphere_height - get_elevation()) / atmosphere_height * 100
	return density

# Drag is a force that is applied to the vessel. The amount of drag a vessel feels
# is related to its speed, angle, and altitude
# Drag is calculated with the following (-C * v2)
# Need to include elevation as well as rotation as a part of the equation
func _calc_drag_forces() :
	# 1. the current thickness of the atmosphere
	var density = _get_atmosphere_density()

	# 2. we need to know how fast we're flying through the atmosphere
	var velocity = get_linear_velocity()

	# 3. the direction (Vector) that the rocket is flying towards (prograde)

	# 4. the angle that the rocket is flying
	
	var aero_drag_amount = 0.5
	
	if is_flopping and rotation_degrees < -75 and rotation_degrees > -115 :
		aero_drag_amount = 2

	drag.y = aero_drag_amount * velocity.y
	drag.x = aero_drag_amount * velocity.x

	return -drag
	
func _calc_lift_forces() :
	var lift_amount = 2
	var velocity = get_linear_velocity()
	
	if rotation_degrees < -50 and rotation_degrees > -75 :
		lift.y = lift_amount * velocity.y
		lift.x = -32
	elif rotation_degrees < -75 and rotation_degrees > -115 :
		lift = Vector2.ZERO
	elif rotation_degrees < -115  and rotation_degrees > -145 :
		lift.y = lift_amount * velocity.y
		lift.x = 0
	elif rotation_degrees < -145 :
		lift.y = lift_amount * velocity.y
		#lift.y = ( lift_amount / 2 ) * velocity.y
		lift.x = 32
		
	return -lift

func get_elevation() -> float:
	
	# Need to get level data. To check if there are any tiles directly below me
	# if there are any tiles on the x-axis below me, then grab their global position and
	# subtract it from the global position of the starship
	# that number is the distance to the ground
	
	elevation = initial_elevation - global_position.y
	return elevation

func _on_Throttle_value_changed( value ) :
	throttle = value

func can_belly_flop() -> bool :
	
	if is_falling and !is_flopping and !thrust_direction_ray.is_colliding() :
		emit_signal( "can_belly_flop", true )
		return true
	else : 
		emit_signal( "can_belly_flop", false )
		return false
		
func is_on_the_ground() -> bool:
	# On the ground
	if get_colliding_bodies().size() > 0 :
		return true
	else :
		# Sets the previous velocity before the next check
		previous_velocity = get_linear_velocity()
		return false
		
func calculate_trajectory() :
	var points = []
	var total_air_time = 20.0
	var x_component = linear_velocity.x * cos (self.rotation * -1.0)
	var y_component = linear_velocity.y * cos (self.rotation * -1.0)

	for point in num_of_points :
		var time = total_air_time * point / num_of_points
		var dx = time * x_component
		var dy = -1.0 * (time * y_component + 0.5 * -9.8 * time * time )

		points.append(Vector2(dx, dy))
	
		$Trajectory.points = points
# ------------------------------------------------------------------
# State Changes - these methods need to be defined in StateMachine.gd
# 
# Entered States: on_enter_name_state()
# Transition State: on_transition_name_state()
# Exit States: on_exit_name_state()
# ------------------------------------------------------------------
func on_enter_flopping_state() :
	is_flopping = true
	# Little bit hacky but it works. Allows interpolation on the rotation_degrees
	$Tween.interpolate_property(self, 'rotation_degrees', null, -100, 2, Tween.TRANS_LINEAR, Tween.EASE_OUT_IN)
	$Tween.start()
	animationPlayer.play("BellyFlop")

func on_enter_flipping_state():
	is_flipping = true
	animationPlayer.play("FlipManuever")

func on_enter_crash_state():
	visible = false
	remaining_fuel = 0
	var explosion = ExplosionEffect.instance()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
