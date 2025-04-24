extends StaticBody3D

var flashlight
var pickup_sound

func _ready() -> void:
	flashlight = get_node("/root/" + get_tree().current_scene.name + "/Player/head/flashlight")
	pickup_sound = get_node("/root/" + get_tree().current_scene.name + "/Sounds/obj_pickup")
	
func interact():
	flashlight.picked_up = true
	pickup_sound.play()
	queue_free()		# flashlight removed from scene
