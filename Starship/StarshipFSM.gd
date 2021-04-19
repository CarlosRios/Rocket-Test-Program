extends "res://StateMachine.gd"

# Define each of our flying states
func _ready() :
	add_state("launching")
	add_state("climbing")
	add_state("falling")
	add_state("flopping")
	add_state("flipping")
	add_state("landing")
	add_state("landed")
	add_state("crashed")
	call_deferred("set_state", states.launching)

# Happens each time the game loop runs _physics_process()
func _state_logic(delta) :
	parent._apply_gravity(delta)
	parent._check_throttle_input()
	parent._check_thrust_input(delta)
	parent._check_steering_input()

# Sets what transitions can happen from each state.
# Determines the rules that change states
# Gets checked every loop
func _get_transition(_delta) :
	match state:
		states.launching:
			if !parent.is_on_floor() && parent.velocity.y < 0 :
				return states.climbing
		
		# Only changes to falling state if we're not too close to the ground
		states.climbing:
			if parent.velocity.y > 0 :
				return states.falling
			
		states.falling:
			if parent.is_flopping:
				return states.flopping
			elif parent.to_ground.is_colliding() && parent.velocity.y > 0:
				return states.landing
			
		# Landing sequence should only be entered from the flipped sequnce
		states.flopping:
			if parent.is_on_floor():
				return states.crashed
			elif parent.thrust < 0 :
				return states.flipping

		states.flipping:
			if parent.is_on_floor() :
				return states.crashed
			elif parent.velocity.y < 0 :
				return states.climbing
			else :
				return states.landing
				
		states.landing:
			if parent.previous_velocity.y > parent.max_damage and parent.is_on_floor() :
				return states.crashed
			elif parent.is_on_floor() :
				return states.landed
			elif parent.velocity.y < 0 :
				return states.climbing
				
		states.landed:
			if !parent.is_on_floor() :
				return states.launching

	return null

# Happens when we enter a new state
func _enter_state(new_state, old_state) :
	match new_state:
		states.launching:
			parent._kill_horizontal_velocity()
			parent.animationPlayer.play("Launching")
			parent.is_in_the_air = false
		
		states.climbing:
			parent.is_falling = false
		
		states.flopping:
			parent.animationPlayer.play("BellyFlop")
		
		states.flipping:
			parent.animationPlayer.play("FlipManuever")
		
		states.landing:
			pass
		
		states.landed:
			parent._kill_horizontal_velocity()
			parent.is_in_the_air = false

		states.crashed:
			parent._starship_has_crashed()

# Happens when we exit a state
func _exit_state(old_state, new_state) :
	match old_state:
		states.launching:
			parent.is_in_the_air = true
			
		states.climbing:
			parent.is_falling = true
			parent.can_belly_flop()

		states.landing:
			parent.is_in_the_air = true
			
		states.flopping:
			parent.is_flopping = false
