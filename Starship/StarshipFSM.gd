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
	#print(states[state])
	pass

# Sets what transitions can happen from each state.
# Determines the rules that change states
# Gets checked every loop
func _get_transition(_delta) :
	match state:
		states.launching:
			if !parent.is_landed() and parent.linear_velocity.y < 0 :
				return states.climbing
		
		# Only changes to falling state if we're not too close to the ground
		states.climbing:
			if parent.linear_velocity.y > 0 :
				return states.falling
			
		states.falling:
			if parent.is_flopping:
				return states.flopping
			elif parent.to_ground.is_colliding() and parent.linear_velocity.y > 0:
				return states.landing
			
		# Landing sequence should only be entered from the flipped sequnce
		states.flopping:
			if parent.is_landed():
				return states.crashed
			elif parent.thrust.y < 0 :
				return states.flipping

		states.flipping:
			if parent.is_landed() :
				return states.crashed
			elif parent.linear_velocity.y < 0 :
				return states.climbing
			else :
				return states.landing
				
		states.landing:
			if parent.previous_velocity.y > parent.max_damage and parent.is_landed() :
				return states.crashed
			elif parent.is_landed() :
				return states.landed
			elif parent.linear_velocity.y < 0 :
				return states.climbing
				
		states.landed:
			if !parent.is_landed() :
				return states.launching

	return null

# Happens when we enter a new state
func _enter_state(new_state, old_state) :

	match new_state:
		states.launching:
			#print("Launching")
			parent.animationPlayer.play("Launching")
			parent.is_in_the_air = false
		
		states.climbing:
			#print("Climbing")
			parent.is_falling = false
		
		states.flopping:
			#print("Flopping")
			parent.animationPlayer.play("BellyFlop")
		
		states.flipping:
			#print("Flipping")
			parent.animationPlayer.play("FlipManuever")
		
		states.landing:
			#print("Landing")
			pass
		
		states.landed:
			#print("Landed")
			parent.is_in_the_air = false

		states.crashed:
			#print("Crashed")
			parent.init_starship_crash()

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
