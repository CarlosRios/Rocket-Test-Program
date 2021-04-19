extends Camera2D

onready var tween = $Tween

func update_camera_zoom(elevation) :
	
	if elevation > 300 :
		zoom.x = 1.5
		zoom.y = 1.5
	else :
		zoom.x = 2.5
		zoom.y = 2.5
