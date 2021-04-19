extends Control

var throttle = 0

func _physics_process(_delta: float) -> void :

	var previous_throttle = throttle
	
	# Handles the throttle
	if Input.is_action_pressed("throttle_up") and throttle < self.max_value :
		throttle += 1
	elif Input.is_action_pressed("throttle_down") and throttle > self.min_value :
		throttle += -1
	elif Input.is_action_pressed( "max_throttle" ) :
		throttle = 100
	elif Input.is_action_pressed( "min_throttle" ) :
		throttle = 0	

	if throttle != previous_throttle :
		update_progress_bar( throttle )

func update_progress_bar( value ) :
	self.value = clamp(value, self.min_value, self.max_value)

# Handles dragging when done within the margin of the throttle node
func _on_Throttle_gui_input(event) -> void:
	
	var input_container_position = self.rect_position.y
	
	if event is InputEventScreenDrag:
		#input_size = event.get_position().y - input_size
		var progress_height = input_container_position - event.get_position().y
		
		#print(progress_height)
		update_progress_bar(progress_height)
		
