extends AnimatedSprite

# Called when the node enters the scene tree for the first time.
func _ready() :
	frame = 0
	play("Animate")

func _on_Explosion_animation_finished() -> void:
	queue_free()
