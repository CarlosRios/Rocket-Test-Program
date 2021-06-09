extends Node2D

export var smoke_effect: PackedScene

var direction_points = []
var num_of_points = 20

onready var starship = $Starship
onready var landing_pad = $SandyBeach/LandingPad
onready var to_landing_pad = $ToLandingPad
onready var prograde = $HUD/ProgradeControl
onready var prograde_arrow = $Prograde
onready var engine_control = $HUD/EngineControl/Buttons.get_children()
onready var engines = $Starship/EngineConfiguration.get_children()
onready var trajectory = $HUD/Trajectory

onready var forward_drag_line = $ForwardDrag
onready var side_drag_line = $SideDrag

# Connect signals here between instanced scenes
func _ready():
	# Starship > Hud
	$Starship.connect("fuel_updated", $HUD, "_on_Fuel_Updated")
	$Starship.connect("can_belly_flop", $HUD, "_on_Can_Belly_Flop")
	$Starship.connect("elevation_updated", $HUD, '_on_Elevation_Updated')

	# Starship > World
	$Starship.connect("launching", self, "generate_smoke_effect")

	# HUD > Starship
	$HUD/Throttle.connect("value_changed", starship, "_on_Throttle_value_changed")
	_connect_engine_button_signals()
	
	# Flightpath
	$Starship.connect("starship_position", $FlightPath, "_on_Starship_Position_Change" )

func _physics_process(_delta: float) :
	_handle_stats()

func _input( _event = Input ) :
	# Handles input
	if Input.is_action_just_pressed( "toggle_all_engines" ) :
		toggle_button(engine_control[0])
		toggle_button(engine_control[1])
		toggle_button(engine_control[2])

	if Input.is_action_just_pressed("toggle_engine_1") :
		toggle_button(engine_control[0])

	if Input.is_action_just_pressed("toggle_engine_2") :
		toggle_button(engine_control[1])

	if Input.is_action_just_pressed("toggle_engine_3") :
		toggle_button(engine_control[2])

func _connect_engine_button_signals() :
	for engine_button in engine_control :
		engine_button.connect( 'toggled', starship, '_on_EngineButton_toggle', [ engine_control.find(engine_button,0)] )

func toggle_button( button ) :
	if button.pressed == true :
		button.pressed = false
	else :
		button.pressed = true

# ======================
# Data related functions
# ======================

func _handle_stats() :
	_update_prograde_stat()
	_update_drag_stats()
	var angle_to_landing_pad = landing_pad.global_position.angle_to( starship.global_position )
	$HUD/DirectionArrow/Sprite.rotation = angle_to_landing_pad
	to_landing_pad.points = [landing_pad.global_position, starship.global_position]

# Rotates the prograde arrow towards the linear velocity of Starship
func _update_prograde_stat() :
	var angle = rad2deg( Vector2(0,0).angle_to_point( starship.linear_velocity.round() ) ) - 90
	if starship.is_on_the_ground() :
		angle = 0
	prograde.set_rotation( deg2rad( angle ) )

	var prograde_location = Vector2()
	prograde_location.x = starship.global_position.x + clamp( starship.linear_velocity.x, -220, 220 )
	prograde_location.y = starship.global_position.y + clamp( starship.linear_velocity.y, -220, 220 )
	
	prograde_arrow.global_position = prograde_location

func _update_drag_stats() :
	var f_points = []
	var s_points = []

	f_points.append( starship.f_vector )
	f_points.append( starship.f_drag )
	s_points.append( starship.s_vector )
	s_points.append( starship.s_drag )

	forward_drag_line.global_position = starship.global_position
	side_drag_line.global_position = starship.global_position

	forward_drag_line.points = f_points
	side_drag_line.points = s_points

# ========
# FX
# ========
func generate_smoke_effect( hit_position: Vector2 )->void:
	var temp = smoke_effect.instance()
	add_child(temp)
	temp.position = hit_position
