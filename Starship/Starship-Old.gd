extends KinematicBody2D

var rotation_dir = 0

const ACCELERATION = 400

export var gravity = 3000.0
export var speed = Vector2( 100, 2000 )
var rotation_speed = 1.5 
var velocity = Vector2.ZERO

func _physics_process(delta):
	
	var direction = get_direction()
	
	velocity = speed * direction
	
	#Apply gravity as well as maximum velocity
	velocity.y += gravity * delta
	velocity.y = max( velocity.y, speed.y )

	print(velocity.y)
	
	rotation += rotation_dir * rotation_speed * delta
	velocity = move_and_slide(velocity)

func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		-1.0 if Input.is_action_pressed("ui_up") else 1.0
	)

func calc_move_velocity(
	linear_velocity: Vector2,
	speed: Vector2,
	direction: Vector2
	) -> Vector2:
	return speed * direction

func get_input():
	rotation_dir = 0
		
	# If the space bar is pressed
	# Space bar is key 32
	if Input.is_action_pressed("ui_up"):
		velocity -= Vector2(0, 200).rotated(rotation)


	if Input.is_action_pressed("ui_left"):
		rotation_dir += -2

	if Input.is_action_pressed("ui_right"):
		rotation_dir += 2

