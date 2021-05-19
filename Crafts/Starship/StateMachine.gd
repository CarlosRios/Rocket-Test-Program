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
	pass

# Sets what transitions can happen from each state.
# Determines the rules that change states
# Gets checked every loop
func _get_transition(_delta) :
	match state:
		states.launching:
			if parent.get_linear_velocity().y < 0 :
				return states.climbing
		
		# Only changes to falling state if we're not too close to the ground
		states.climbing:
			if parent.get_linear_velocity().y > 0 :
				return states.falling
			
		states.falling:
			if parent.is_flopping:
				return states.flopping
			elif parent.thrust_direction_ray.is_colliding() and parent.get_linear_velocity().y > 0:
				return states.landing
			elif parent.is_on_the_ground():
				return states.crashed
			
		# Landing sequence should only be entered from the flipped sequnce
		states.flopping:
			if parent.is_on_the_ground():
				return states.crashed
			elif parent.is_thrusting() :
				return states.flipping

		states.flipping:
			if parent.is_on_the_ground() :
				return states.crashed
			elif parent.get_linear_velocity().y < 0 :
				return states.climbing
			else :
				return states.landing
				
		states.landing:
			if parent.is_on_the_ground() :
				if parent.previous_velocity.y > parent.max_landing_velocity :
					return states.crashed
				else :
					return states.landed
			elif parent.linear_velocity.y < 0 :
				return states.climbing
				
		states.landed:
			if parent.get_linear_velocity().y < -1:
				return states.launching

	return null

# Happens when we enter a new state
func _enter_state(new_state, old_state) :

	match new_state:
		states.launching:
			parent.on_enter_launching_state()
		
		states.climbing:
			parent.on_enter_climbing_state()
		
		states.falling:
			parent.can_belly_flop()
			
		states.flopping:
			parent.on_enter_flopping_state()
		
		states.flipping:
			parent.on_enter_flipping_state()

		states.landing:
			pass
		
		states.landed:
			parent.is_in_the_air = false

		states.crashed:
			parent.on_enter_crash_state()

# Happens when we exit a state
func _exit_state(old_state, new_state) :
	match old_state:
		states.launching:
			parent.on_exit_launching_state()

		states.climbing:
			parent.is_falling = true

		states.landing:
			parent.is_in_the_air = true
			
		states.flopping:
			parent.is_flopping = false

		states.flipping:
			parent.is_flipping = false
