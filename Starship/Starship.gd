extends KinematicBody2D

const UP = Vector2(0, -1)
export var GRAVITY = 90
export var MAX_SPEED = 250.0
var speed = 0

#Death effect
const ExplosionEffect = preload("res://Effects/Explosion.tscn")

export var max_fuel = 300.00
onready var remaining_fuel = max_fuel
export var max_damage = 60

var velocity = Vector2.ZERO
var previous_velocity = Vector2.ZERO
var throttle = 0.0
var thrust = 0
var rotation_dir = 0
var engine_gimbal_dir = null
var is_in_the_air = false
var is_falling = false
var is_flopping = false

# Distances
onready var initial_elevation = global_position.y
var elevation = 0

onready var animationPlayer = $AnimationPlayer
onready var smoke_ray = $Smoke/RayCast2D
onready var engines = $EngineThrust/Particles2D
onready var to_ground = $DistanceFromGround
onready var camera = $Camera2D
onready var direction_arrow = $DirectionArrow

# Thrusters - need to do this better, too much recurring code
onready var rcs_left_aft = $Thrusters/AftLeft/Particles2D
onready var rcs_left_forward = $Thrusters/ForwardLeft/Particles2D
onready var rcs_right_aft = $Thrusters/AftRight/Particles2D
onready var rcs_right_forward = $Thrusters/ForwardRight/Particles2D

signal launching
signal engines_on
signal can_belly_flop
signal fuel_updated

func _physics_process(_delta: float) -> void:
	
	previous_velocity = velocity
	
	_point_arrow_to_ground()
	
	#Always point to the ground
	to_ground.global_rotation = 0

	rotation += rotation_dir * 1 * _delta

	velocity = move_and_slide( velocity, UP )
	
	camera.update_camera_zoom(get_elevation())

# Need to rework gravity so that it doesn't become infinite on falling
# This could be done by providing some resistance from the atmosphere
func _apply_gravity(delta) :
	if velocity.y < GRAVITY :
		velocity.y += GRAVITY
		
	#print( velocity )
	
	##velocity = velocity.clamped(GRAVITY )
		
func get_elevation() -> float:
	
	# Need to get level data. To check if there are any tiles diirectly below me
	# if there are any tiles on the x-axis below me, then grab their global position and
	# subtract it from the global position of the starship
	# that number is the distance to the ground
	
	elevation = initial_elevation - global_position.y
	return elevation

# Connects via signal in World.gd
func _on_Throttle_value_changed( value ) :
	throttle = value

func _check_throttle_input() :

	if Input.is_action_pressed("belly_flop") && can_belly_flop() :
		is_flopping = true

func _calc_fuel_consumption() :
	if remaining_fuel > 0 :
		var fuel_burn_formula = throttle / 100
		remaining_fuel -= fuel_burn_formula

func _check_thrust_input(delta):
	# Starship is accelerating
	if Input.is_action_pressed("fire_engines") and remaining_fuel > 0:
		
		_calc_fuel_consumption()
		
		emit_signal("fuel_updated", max_fuel, remaining_fuel)

		camera.get_child(0).start()
		
		if smoke_ray.is_colliding():
			emit_signal("launching", smoke_ray.get_collision_point() )
		
		# Clamp the speed, and apply it to the velocity in a rotated position
		#speed = throttle * MAX_SPEED * delta
		#speed = clamp(speed, 0, MAX_SPEED)
		#print( speed )
		
		if velocity.y < MAX_SPEED: 
			velocity.y = MAX_SPEED
		else :
			#Calculates the thrust 
			thrust = throttle * MAX_SPEED * delta
			
			#Falling / Climbing speed
			velocity += Vector2(0, thrust).rotated(rotation)
			
			#print( thrust )
		
		emit_signal("engines_on", true, thrust, engine_gimbal_dir)
		
	# reset the thrust for the belly flop
	if Input.is_action_just_released("fire_engines") :
		thrust = 0
		emit_signal("engines_on", false, thrust, engine_gimbal_dir )

# Handles rotation and steering.
# Need to allow for x-axis course correction based on rotation.
func _check_steering_input() :
	rotation_dir = 0

	if Input.is_action_pressed("ui_left") && !is_on_floor() && !is_flopping:
		rotation_dir += -2
		engine_gimbal_dir = "left"
		rcs_left_forward.emitting = true
		rcs_right_aft.emitting = true
		
	elif Input.is_action_pressed("ui_right") && !is_on_floor() && !is_flopping:
		rotation_dir += 2
		engine_gimbal_dir = "right"
		rcs_right_forward.emitting = true
		rcs_left_aft.emitting = true
		
	elif Input.is_action_pressed("ui_up") && is_flopping :
		rotation_dir += 2
		_handle_rotational_velocity()
		engine_gimbal_dir = "right"
		rcs_right_forward.emitting = true
		rcs_left_aft.emitting = true

	elif Input.is_action_pressed("ui_down") && is_flopping :
		rotation_dir += -2
		_handle_rotational_velocity()
		engine_gimbal_dir = "left"
		rcs_left_forward.emitting = true
		rcs_right_aft.emitting = true
	else :
		engine_gimbal_dir = null

# Handles the drag / lift of the vehicle when executing the belly flop
func _handle_rotational_velocity() :
	
	if rotation_degrees >= 100 and rotation_degrees <= 110 :
		velocity.x += 1
	elif rotation_degrees <= -100 and rotation_degrees >= -110 :
		velocity.x += -1
	elif rotation_degrees >= 110 and rotation_degrees <= 120 :
		velocity.x += 2
	elif rotation_degrees <= -110 and rotation_degrees >= -120 :
		velocity.x += -2
	elif rotation_degrees >= 120 and rotation_degrees <= 130 :
		velocity.x += 3
	elif rotation_degrees <= -120 and rotation_degrees >= -130 :
		velocity.x += -3

func _kill_horizontal_velocity() :
	velocity = Vector2( 0, velocity.y )
	
func can_belly_flop() -> bool :
	
	if is_falling && !is_flopping && !to_ground.is_colliding() :
		emit_signal( "can_belly_flop", true )
		return true
	else : 
		emit_signal( "can_belly_flop", false )
		return false

func _starship_has_crashed() :
	#queue_free()
	velocity = Vector2.ZERO
	visible = false
	remaining_fuel = 0
	var explosion = ExplosionEffect.instance()
	get_parent().add_child(explosion)
	explosion.global_position = global_position

func _point_arrow_to_ground() :
	var angle_to_ground = direction_arrow.get_angle_to(Vector2.DOWN)
	
	#print(angle_to_ground)
	direction_arrow.rotate(angle_to_ground)
