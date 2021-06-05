extends Control

## Need to get the engine data to work here.
onready var engines = get_tree()

func _process(_delta) :
	_handle_engine_input()

func _handle_engine_input() :

	if Input.is_action_just_pressed("toggle_engine_1") :
		#print( engines )
		pass
