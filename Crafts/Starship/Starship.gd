extends RigidBody2D

# Constants
const ExplosionEffect = preload("res://Effects/Explosion.tscn")

# Signals
signal fuel_updated
signal can_belly_flop
signal elevation_updated
signal starship_position

# Exports
export (float) var max_fuel = 1200
export (float) var max_landing_velocity = 50.00
export (int) var atmosphere_height = 10000

# Variables
var elevation = 0
var lift = Vector2()
var previous_velocity = Vector2.ZERO
var throttle = 0.0
var rotation_dir = 0
var num_of_points = 10
var dry_mass = 120
var travel_path = []

# Drag Vectors
var f_vector = Vector2(0, -87).rotated( self.rotation )
var s_vector = Vector2( -16, 0 ).rotated( self.rotation )
var s_drag = Vector2()
var f_drag = Vector2()

# Conditional Variables
var is_in_the_air = false
var is_falling = false
var is_flopping = false
var is_flipping = false
var is_landed = true
var is_crashed = false

# Onreadys
#onready var to_ground = $DistanceFromGround
onready var gravity = Physics2DServer.area_get_param( get_world_2d().get_space(), Physics2DServer.AREA_PARAM_GRAVITY)
onready var engines = $EngineConfiguration.get_children()
onready var animationPlayer = $AnimationPlayer
onready var thrust_direction_ray = $ThrustDirectionRay
onready var camera = $Camera2D
onready var liftoff_audio = $LiftoffAudio
onready var collider = $CollisionShape2D
onready var remaining_fuel = max_fuel
onready var initial_elevation = global_position.y

# ------------------------------------------------------------------
# Main functions _ready() _physics_process _process
# ------------------------------------------------------------------
func _ready() :
	set_vehicle_mass()

func _physics_process(_delta: float) :
	_handle_input()
	_engine_controller()
	_calc_drag_forces()
	_handle_camera()
	_handle_audio()

# ------------------------------------------------------------------
# Handles the flight input
# ------------------------------------------------------------------
func _handle_input() :

	if Input.is_action_pressed("ui_right") :
		apply_rcs_torque("right")
		steer_engines('right')

	if Input.is_action_pressed("ui_left") :
		apply_rcs_torque("left")
		steer_engines('left')

	if Input.is_action_just_released("ui_right") or Input.is_action_just_released( "ui_left" ) :
		steer_engines()
	
	if Input.is_action_pressed("belly_flop") && can_belly_flop() :
		is_flopping = true

# Everything related to the camera
func _handle_camera() :
	if is_thrusting() :
		camera.get_child(1).start()

	camera.update_camera_zoom( get_elevation() )

# Handles the audio
func _handle_audio() :
	if !is_thrusting() :
		liftoff_audio.playing = false

func toggle_audio( _audio_state = null ) :
	if _audio_state == true :
		liftoff_audio.playing = true
	elif _audio_state == false :
		liftoff_audio.playing = false
	else :
		if liftoff_audio.playing == false :
			liftoff_audio.playing = true

# ------------------------------------------------------------------
# Force / Impulse related functions
# ------------------------------------------------------------------

# Starship's dry mass is 120 tonnes
# SN Tests weigh about 5000 tonnes
# Raptors max thrust is around 225 tonnes, min is 90 tonnes
func set_vehicle_mass() : 
	mass = dry_mass + remaining_fuel

# Activates all the engines or a specific engine
func _engine_controller( _engine = null ) :
	if remaining_fuel > 0 :
		if _engine == null:
			for engine in engines :
				if engine.is_on() and throttle > 0:
					engine.apply_thrust( throttle )
					burn_fuel_with_engines(engine)
				else :
					engine.thrust = 0
		elif _engine != null : 
			engines[_engine].turn_on()

# Toggles all the engines.
# Set _engine_state to true / false to force on or off state, leave blank to toggle
func toggle_all_engines( _engine_state = null ) :
	for engine in engines :
		if _engine_state != null :
			toggle_engine( engine, _engine_state )
		else :
			toggle_engine( engine )

# Toggles the engine
# _engine_state can be used to force a shutdown / activation
# such as in the case where you want to shutdown everything or turn on everything.
func toggle_engine( engine_node, _engine_state = null ) :

	if _engine_state != null :
		if _engine_state == true :
			engine_node.turn_on()
		else :
			engine_node.shut_down()
	else : 
		if engine_node.is_on() :
			engine_node.shut_down()
		else :
			engine_node.turn_on()

func steer_engines( direction = null ) :
	for engine in engines : 
		engine.set_engine_rotation( direction )

func apply_rcs_torque( direction, strength = 40000 ) :
	if direction == "left" :
		apply_torque_impulse(-strength)
	else :
		apply_torque_impulse(strength)

func burn_fuel_with_engines( engine ) :
	#toggle_audio()
	var fuel_consumption = engine.thrust / ( engine.isp * gravity )
	remaining_fuel -= fuel_consumption
	set_vehicle_mass()
	emit_signal("fuel_updated", max_fuel, remaining_fuel)

func dump_fuel() :
	remaining_fuel = 0
	emit_signal("fuel_updated", max_fuel, 0.0)

# Calculates how dense the atmosphere is.
# Returns a percentage
func _get_atmosphere_density() :
	# higher is closer to sea level
	# lower is closer to space.
	var density = (atmosphere_height - get_elevation()) / atmosphere_height * 100
	return density

# Drag is a force that is applied to the vessel. The amount of drag a vessel feels
func _calc_drag_forces() :
	var density = _get_atmosphere_density()

	if density > 0 :
		var s = s_vector.rotated(global_rotation).normalized()
		var f = f_vector.rotated(global_rotation).normalized()
		var v = linear_velocity.normalized()

		var sdot = v.dot(s)
		var fdot = v.dot(f)

		s_drag = abs(sdot) * sdot * s * ( density / 100 ) * 1.0 * linear_velocity.length()
		f_drag = abs(fdot) * fdot * f * ( density / 100 ) * 0.25 * linear_velocity.length()

		apply_impulse( Vector2.ZERO, -f_drag )
		apply_impulse( Vector2.ZERO, -s_drag )

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
	emit_signal( 'elevation_updated', round(elevation) )
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

func is_thrusting() -> bool :
	var vehicle_thrust = 0.0
	for engine in engines :
		vehicle_thrust += engine.thrust

	if vehicle_thrust > 0 :
		return true 
	else :
		return false

func _calculate_trajectory() :
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
# Input Events - these are methods that are connected via signal externally
# ------------------------------------------------------------------
func _on_EngineButton_toggle(_button_pressed, engine_number) :
	toggle_engine( engines[ engine_number ] )

# ------------------------------------------------------------------
# State Changes - these methods need to be defined in StateMachine.gd
# 
# Entered States: on_enter_name_state()
# Transition State: on_transition_name_state()
# Exit States: on_exit_name_state()
# ------------------------------------------------------------------
func on_enter_launching_state() :
	animationPlayer.play("Launching")
	is_in_the_air = false

func on_exit_launching_state() :
	is_in_the_air = true
	$StatsUpdate.start()

func on_enter_climbing_state() :
	is_falling = false

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
	dump_fuel()
	visible = false
	var explosion = ExplosionEffect.instance()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	for engine in engines :
		engine.shut_down()
	$StatsUpdate.stop()


func _on_StatsUpdate_timeout() -> void:
	var starship_height = collider.shape.extents.y
	emit_signal('starship_position', global_position )
