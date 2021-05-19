extends Camera2D

const TRANS = Tween.TRANS_CUBIC
const EASE = Tween.EASE_IN_OUT
const DURATION = 0.1

onready var zoomTween = $ZoomTween

func update_camera_zoom(elevation) :
	
	if elevation > 1000 :
		$ZoomTween.interpolate_property(self, "zoom:x", null, 1.0, DURATION, TRANS, EASE)
		$ZoomTween.interpolate_property(self, "zoom:y", null, 1.0, DURATION, TRANS, EASE)
		$ZoomTween.start()
	else :
		$ZoomTween.interpolate_property(self, "zoom:x", null, 1.5, DURATION, TRANS, EASE)
		$ZoomTween.interpolate_property(self, "zoom:y", null, 1.5, DURATION, TRANS, EASE)
		$ZoomTween.start()
